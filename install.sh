#!/bin/sh

# ============================================================
# Hyperia - Host dependency installer
# ============================================================

set -u

# ------------------------------------------------------------
# Colors
# ------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# # ------------------------------------------------------------
# # Logging functions
# # ------------------------------------------------------------

info() {
    echo "${BLUE}[INFO]${NC} $1"
}

success() {
    echo "${GREEN}[ OK ]${NC} $1"
}

warning() {
    echo "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo "${RED}[ERROR]${NC} $1"
}

die() {
    error "$1"
    exit 1
}

welcome(){
clear
echo
echo "============================================================"
echo "                 Hyperia Host Setup"
echo "============================================================"
echo
echo "This script will install the dependencies required by"
echo "Hyperia for virtualization and container management."
echo
}

check_root(){
    if [ "$(id -u)" -ne 0 ]; then
        warning "Root privileges are required."
        info "Requesting sudo privileges..."

        exec sudo "$0" "$@"
    fi

    success "Running with root privileges."
}

detect_os() {

    [ -f /etc/os-release ] || die "Cannot determine operating system."

    . /etc/os-release

    DISTRO_ID="$ID"
    DISTRO_NAME="$PRETTY_NAME"

    info "Detected OS: $DISTRO_NAME"

    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"
    else
        die "Unsupported package manager."
    fi

    success "Using package manager: $PKG_MANAGER"
}

change_hostname() {
    HOSTNAME=$(whiptail \
        --title "Hyperia Setup" \
        --inputbox "Enter the server hostname:" \
        10 60 \
        "hyperia-node01" \
        3>&1 1>&2 2>&3
    )

    STATUS=$?

    if [ "$STATUS" -ne 0 ]; then
        echo "No hostname entered. Keeping current hostname."
        return 0
    fi

    if [ -z "$HOSTNAME" ]; then
        echo "No hostname entered. Keeping current hostname."
        return 0
    fi

    set_hostname
}

set_hostname() {

    [ -z "$HOSTNAME" ] && return 0

    info "Setting hostname to '$HOSTNAME'..."

    if hostnamectl set-hostname "$HOSTNAME"; then
        success "Hostname changed successfully."
    else
        die "Failed to change hostname."
    fi
}

update_repositories() {

    info "Updating repositories..."

    case "$PKG_MANAGER" in
        apt)
            apt update > /dev/null 2>&1  && apt upgrade -y > /dev/null 2>&1 || die "APT update failed."

            ;;
        dnf)
            dnf makecache > /dev/null 2>&1 || die "DNF cache refresh failed."
            ;;
    esac

    success "Repositories updated."
}

check_cpu_support() {
    echo
    info "Checking CPU virtualization support..."

    if grep -Eq 'vmx|svm' /proc/cpuinfo; then
        if grep -q 'vmx' /proc/cpuinfo; then
            success "Intel VT-x virtualization support detected."
        elif grep -q 'svm' /proc/cpuinfo; then
            success "AMD-V virtualization support detected."
        fi
    else
        die "Hardware virtualization is not available.

    Enable Intel VT-x / AMD-V (SVM) in the system BIOS/UEFI
    and run this script again."
    fi
}


install_dependencies() {

    info "Installing Hyperia dependencies..."

    if [ "$PKG_MANAGER" = "apt" ]; then

        PACKAGES="
            qemu-kvm
            libvirt-daemon-system
            libvirt-clients
            bridge-utils
            virtinst
            virt-manager
            cpu-checker
            lxc
            python3
            python3-pip
            python3-venv
            python3-libvirt
            python3-pam
            libpam0g-dev
            pkg-config
            libvirt-dev
            python3-dev
            python3.13-venv
            build-essential
        "

        apt install -y $PACKAGES > /dev/null 2>&1 \
            || die "Failed installing Debian dependencies."

    else

        PACKAGES="
            qemu-kvm
            libvirt
            libvirt-client
            virt-install
            virt-manager
            bridge-utils
            python3
            python3-pip
            python3-devel
            python3-libvirt
            pam-devel
            libvirt-devel
            pkgconf-pkg-config
            gcc
            gcc-c++
            python3.13-venv
            make
        "

        dnf install -y $PACKAGES  > /dev/null 2>&1 \
            || die "Failed installing Fedora dependencies."
    fi

    success "Dependencies installed."
}

enable_libvirt() {

    info "Enabling libvirt..."

    systemctl enable --now libvirtd \
        || warning "Could not start libvirtd."

    info "Adding user to libvirt group"
    
    usermod -aG libvirt "$USER"
    usermod -aG kvm "$USER"

    success "libvirt configured."
}


# # ------------------------------------------------------------
# # Load KVM kernel modules
# # ------------------------------------------------------------

load_kvm_modules() {
echo
info "Checking KVM kernel modules..."

if grep -q 'vmx' /proc/cpuinfo; then
    info "Intel CPU detected. Loading kvm_intel..."
    
    if modprobe kvm_intel 2>/dev/null; then
        success "kvm_intel loaded."
    else
        warning "Could not manually load kvm_intel."
    fi

elif grep -q 'svm' /proc/cpuinfo; then
    info "AMD CPU detected. Loading kvm_amd..."

    if modprobe kvm_amd 2>/dev/null; then
        success "kvm_amd loaded."
    else
        warning "Could not manually load kvm_amd."
    fi
fi

# # ------------------------------------------------------------
# # Check KVM module
# # ------------------------------------------------------------

echo
info "Checking KVM kernel module..."

if lsmod | grep -q '^kvm'; then
    success "KVM kernel module is loaded."
else
    die "KVM kernel module is not loaded."
fi

# # ------------------------------------------------------------
# # Check /dev/kvm
# # ------------------------------------------------------------

info "Checking /dev/kvm..."

if [ -e /dev/kvm ]; then
    success "/dev/kvm is available."
else
    die "/dev/kvm does not exist.

KVM cannot be used on this system."
fi

# # ------------------------------------------------------------
# # Check KVM acceleration
# # ------------------------------------------------------------

echo
info "Testing KVM acceleration..."

if command -v kvm-ok >/dev/null 2>&1; then

    if kvm-ok >/dev/null 2>&1; then
        success "KVM acceleration is available."
    else
        die "KVM acceleration test failed."
    fi

else
    warning "kvm-ok was not found."
    warning "Skipping KVM acceleration test."
fi
}

# # ------------------------------------------------------------
# #  QEMU
# # ------------------------------------------------------------

enable_qemu() {
echo
info "Checking QEMU..."

if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    QEMU_VERSION=$(qemu-system-x86_64 --version | head -n 1)
    success "QEMU installed: $QEMU_VERSION"
else
    die "qemu-system-x86_64 was not found."
fi

# # ------------------------------------------------------------
# # Check libvirt
# # ------------------------------------------------------------

echo
info "Checking libvirt..."

if command -v virsh >/dev/null 2>&1; then
    LIBVIRT_VERSION=$(virsh --version)
    success "libvirt installed: $LIBVIRT_VERSION"
else
    die "virsh was not found."
fi

# # ------------------------------------------------------------
# # Enable libvirt
# # ------------------------------------------------------------

info "Enabling libvirt service..."

if systemctl enable --now libvirtd 2>/dev/null; then
    success "libvirt service is running."
else
    warning "Could not start libvirtd."
    warning "This may depend on the installed libvirt service configuration."
fi
}

# # ------------------------------------------------------------
# # Check LXC
# # ------------------------------------------------------------
load_lxc() {
echo
info "Checking LXC..."

if command -v lxc-start >/dev/null 2>&1; then
    success "LXC is installed."
else
    die "LXC was not found."
fi
}

# # ------------------------------------------------------------
# # Check Python
# # ------------------------------------------------------------

setup_python() {
echo
info "Checking Python..."

if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    success "$PYTHON_VERSION"
else
    die "Python3 was not installed."
fi

# # ------------------------------------------------------------
# # Install Python environment
# # ------------------------------------------------------------

info "Creating Python virtual environment..."

if python3 -m venv .venv; then
    success "Python virtual environment created."
else
    die "Failed to create Python virtual environment."
fi

info "Activating Python virtual environment..."

. .venv/bin/activate > /dev/null 2>&1

success "Python virtual environment activated."

# # ------------------------------------------------------------
# # Install requirements
# # ------------------------------------------------------------

if python -m pip install -r requirements.txt; then
    success "Python requirements installed."
else
    die "Python requirements were not installed!"
fi

# # ------------------------------------------------------------
# # Check Python libvirt bindings
# # ------------------------------------------------------------

info "Checking Python libvirt bindings..."

if python3 -c "import libvirt" >/dev/null 2>&1; then
    success "Python libvirt bindings are available."
else
    die "Python libvirt bindings are not working."
fi
}


# # ------------------------------------------------------------
# # Copy Files
# # ------------------------------------------------------------
copy_files() {
    HYPERIA_HOME="/opt/hyperia"
    VENV_PATH="$HYPERIA_HOME/venv"

    mkdir -p "$HYPERIA_HOME"

    python3 -m venv "$VENV_PATH" \
        || die "Failed creating Python environment."

    . "$VENV_PATH/bin/activate"
}

# # ------------------------------------------------------------
# # Final status
# # ------------------------------------------------------------
clear_installation() {
echo
echo "============================================================"
echo "                 Hyperia Setup Complete"
echo "============================================================"
echo

success "CPU virtualization: available"
success "KVM: available"
success "QEMU: installed"
success "libvirt: installed"
success "LXC: installed"
success "Python3: installed"
success "Python libvirt bindings: available"

echo
info "Hyperia host dependencies are ready."
echo
}

main(){
    welcome
    check_root
    detect_os
    change_hostname
    update_repositories
    check_cpu_support
    install_dependencies  
    enable_libvirt
    load_kvm_modules
    enable_qemu
    load_lxc
    setup_python

    clear_installation
}

main "$@"
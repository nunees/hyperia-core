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

# ------------------------------------------------------------
# Logging functions
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

echo
echo "============================================================"
echo "                 Hyperia Host Setup"
echo "============================================================"
echo
echo "This script will install the dependencies required by"
echo "Hyperia for virtualization and container management."
echo

# ------------------------------------------------------------
# Check root privileges
# ------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    warning "Root privileges are required."
    info "Requesting sudo privileges..."

    exec sudo "$0" "$@"
fi

success "Running with root privileges."

# ------------------------------------------------------------
# Check operating system
# ------------------------------------------------------------

if [ ! -f /etc/os-release ]; then
    die "Cannot determine the operating system."
fi

. /etc/os-release

info "Detected operating system: ${PRETTY_NAME}"

if [ "${ID:-}" != "debian" ]; then
    warning "This installer is currently designed for Debian."
    warning "Detected distribution: ${ID:-unknown}"
fi

# ------------------------------------------------------------
# Check CPU virtualization support
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Update package repository
# ------------------------------------------------------------

echo
info "Updating APT package repositories..."

if ! apt update; then
    die "APT repository update failed."
fi

success "APT repositories updated."

# ------------------------------------------------------------
# Install required packages
# ------------------------------------------------------------

echo
info "Installing Hyperia dependencies..."

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
python3-libvirt
libpam0g-dev
python3-pam
pkg-config
libvirt-dev
python3-dev
build-essential
"

if ! apt install -y $PACKAGES; then
    die "Failed to install one or more required packages."
fi

success "Required packages installed."

# ------------------------------------------------------------
# Load KVM kernel modules
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Check KVM module
# ------------------------------------------------------------

echo
info "Checking KVM kernel module..."

if lsmod | grep -q '^kvm'; then
    success "KVM kernel module is loaded."
else
    die "KVM kernel module is not loaded."
fi

# ------------------------------------------------------------
# Check /dev/kvm
# ------------------------------------------------------------

info "Checking /dev/kvm..."

if [ -e /dev/kvm ]; then
    success "/dev/kvm is available."
else
    die "/dev/kvm does not exist.

KVM cannot be used on this system."
fi

# ------------------------------------------------------------
# Check KVM acceleration
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# Check QEMU
# ------------------------------------------------------------

echo
info "Checking QEMU..."

if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    QEMU_VERSION=$(qemu-system-x86_64 --version | head -n 1)
    success "QEMU installed: $QEMU_VERSION"
else
    die "qemu-system-x86_64 was not found."
fi

# ------------------------------------------------------------
# Check libvirt
# ------------------------------------------------------------

echo
info "Checking libvirt..."

if command -v virsh >/dev/null 2>&1; then
    LIBVIRT_VERSION=$(virsh --version)
    success "libvirt installed: $LIBVIRT_VERSION"
else
    die "virsh was not found."
fi

# ------------------------------------------------------------
# Enable libvirt
# ------------------------------------------------------------

info "Enabling libvirt service..."

if systemctl enable --now libvirtd 2>/dev/null; then
    success "libvirt service is running."
else
    warning "Could not start libvirtd."
    warning "This may depend on the installed libvirt service configuration."
fi

# ------------------------------------------------------------
# Check LXC
# ------------------------------------------------------------

echo
info "Checking LXC..."

if command -v lxc-start >/dev/null 2>&1; then
    success "LXC is installed."
else
    die "LXC was not found."
fi

# ------------------------------------------------------------
# Check Python
# ------------------------------------------------------------

echo
info "Checking Python..."

if command -v python3 >/dev/null 2>&1; then
    PYTHON_VERSION=$(python3 --version)
    success "$PYTHON_VERSION"
else
    die "Python3 was not installed."
fi

# ------------------------------------------------------------
# Install Python environment
# ------------------------------------------------------------

info "Creating Python virtual environment..."

if python3 -m venv .venv; then
    success "Python virtual environment created."
else
    die "Failed to create Python virtual environment."
fi

info "Activating Python virtual environment..."

. .venv/bin/activate

success "Python virtual environment activated."

# ------------------------------------------------------------
# Install requirements
# ------------------------------------------------------------

# ------------------------------------------------------------
# Install requirements
# ------------------------------------------------------------

if python -m pip install -r requirements.txt; then
    success "Python requirements installed."
else
    die "Python requirements were not installed!"
fi

# ------------------------------------------------------------
# Check Python libvirt bindings
# ------------------------------------------------------------

info "Checking Python libvirt bindings..."

if python3 -c "import libvirt" >/dev/null 2>&1; then
    success "Python libvirt bindings are available."
else
    die "Python libvirt bindings are not working."
fi

# ------------------------------------------------------------
# Final status
# ------------------------------------------------------------

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

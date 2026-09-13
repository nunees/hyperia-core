from app.virtualization.qemu import QEMUManager


class VMService:

    def __init__(self):
        self.qemu = QEMUManager()

    def list_vms(self):
        return self.qemu.list_vms()

    def start_vm(self, name):
        return self.qemu.start_vm(name)

    def stop_vm(self, name):
        return self.qemu.stop_vm(name)
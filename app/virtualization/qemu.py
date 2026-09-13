import libvirt
from app.utils.logger import HyperiaLogger, LogType


class QEMUManager:

    def __init__(self):
        self.connection = libvirt.open("qemu:///system")
        api_logger = HyperiaLogger.get_logger(LogType.VM)

        if self.connection is None:
            raise RuntimeError("Could not connect to libvirt")

        api_logger.info("Starting QEMU virtualization")

    def list_vms(self):
        domains =  self.connection.listAllDomains()

        return [
            {
                "name": domain.name(),
                "id": domain.ID(),
                "state": domain.state()[0],
            }
            for domain in domains
        ]

    def start_vm(self, name):
        domain = self.connection.lookupByName(name)
        domain.create()

    def stop_vm(self, name):
        domain = self.connection.lookupByName(name)
        domain.shutdown()

    def close(self):
        if self.connection:
            self.connection.close()

import libvirt


class VMManager:
    def __init__(self):
        self.connection = libvirt.open("qemu:///system")

    def list_vms(self):
        domains = self.connection.listAllDomains()

        vms = []

        for domain in domains:
            vms.append(
                {"name": domain.name(), "id": domain.ID(), "state": domain.state()[0]}
            )

        return vms

    def start_vm(self, name):
      domain = self.connection.lookupByName(name)
      domain.create()

    def stop_vm(self, name):
      domain = self.connection.lookupByName(name)
      domain.shutdown()

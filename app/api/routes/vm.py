from fastapi import APIRouter, Depends

from app.core.security import get_current_user
from app.services.qemu_service import VMService
from app.models.create_vm_image_request import CreateVMImageRequest

router = APIRouter(
    prefix="/vms",
    tags=["QEMU Virtual Machines"],
    dependencies=[Depends(get_current_user)],
)

vm_service = VMService()


@router.get("/")
def list_vms():
    return  vm_service.list_vms()


@router.post("/{name}/start")
def start_vm(name: str):
    vm_service.start_vm(name)
    return {"message": "VM started"}

@router.post("/create")
def create_vm(data: CreateVMImageRequest):
    return {
        "name": data.name,
        "smp": data.smp,
        "disksize": data.disksize,
        "ramsize": data.ramsize,
        "isoimage": data.isoimage,
        "format": data.format
    }

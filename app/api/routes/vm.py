from fastapi import APIRouter, Depends

from app.core.security import get_current_user
from app.services.qemu_service import VMService

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

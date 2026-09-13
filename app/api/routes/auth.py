from fastapi import APIRouter

from app.models.auth_model import AuthModel
from app.services.auth_service import AuthService

router = APIRouter(prefix="/auth", tags=["Authentication"])

auth_service = AuthService()

@router.post("/")
def login(credentials: AuthModel):
    return auth_service.auth(credentials)
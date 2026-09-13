from fastapi import FastAPI

from app.api.routes import vm, auth

app = FastAPI(
    title="Hyperia API",
    version="0.1.0"
)

app.include_router(vm.router)
app.include_router(auth.router)



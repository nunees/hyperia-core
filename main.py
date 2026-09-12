from fastapi import FastAPI

from VMManager import VMManager
from auth.authenticate import Authenticate

app = FastAPI(title="Hyperia")


@app.get("/")
def root():
    return {"message": "Hyperia container Management API"}


@app.get("/ping")
def ping():
    return {"message": "pong"}


@app.post("/api/auth")
def auth(data: Authenticate):
    return Authenticate.login(data)


@app.get("/api/vms")
def get_vms():
    VMManager.list_vms()

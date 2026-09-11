from pydantic import BaseModel
import pam
import pwd


class Authenticate(BaseModel):
    username: str
    password: str

    @staticmethod
    def login(credentials):
        authenticator = pam.pam()

        if not authenticator.authenticate(
        credentials.username,
        credentials.password):
          return {"error": "Invalid credentials!"}

        user = pwd.getpwnam(credentials.username)

        if user.pw_uid == 0:
            print("Authenticated as root")
            return {"message": "Root account authenticated"}
        else:
            print("Authenticated as regular user")
            return {"message": "Limited account authenticated"}



from jose import jwt
from datetime import datetime, timedelta, timezone

import pam
import pwd

SECRET_KEY = "change-this-to-a-long-random-secret"
ALGORITHM = "HS256"

class AuthService:

    def auth(self, credentials):

        authenticator = pam.pam()

        #
        # Important Permission RuleBy default, standard Linux systems check user credentials against /etc/shadow
        #  using pam_unix.so. Because /etc/shadow is strictly protected, 
        # your Python script must meet one of two conditions to check passwords: 
        # [1] (https://pypi.org/project/python-pam/)
        # 1 - Running with Root/Sudo Privileges: You can validate any account's 
        # password.
        # 2 - Running as a Non-Root User: You can only validate the password of the specific user 
        # currently executing the script. [1] (https://pypi.org/project/python-pam/)
        #
        authenticated = authenticator.authenticate(
            credentials.username,
            credentials.password,
            service="login"
        )

        if not authenticated:
            print("PAM error:", authenticator.reason)

            return {
                "error": "Invalid credentials!"
            }

        user = pwd.getpwnam(credentials.username)

        print(user)

        if user.pw_uid != 0:
            return {
                "error": "A root account is needed!"
            }

        payload = {
            "sub": credentials.username,
            "uid": user.pw_uid,
            "exp": datetime.now(timezone.utc) + timedelta(hours=1)
        }

        token = jwt.encode(
            payload,
            SECRET_KEY,
            algorithm=ALGORITHM
        )

        return {"access_token": token}
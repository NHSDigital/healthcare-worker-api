import sys
import requests

import jwt
import uuid
from time import time


def generate_jwt():
    realm_url = "https://internal-dev.api.service.nhs.uk/oauth2/token"

    if len(sys.argv) != 4:
        print("Expected format poetry run start <private_key_filename> <key_id> <api_key>")
        exit(1)

    private_key_filename = sys.argv[1]
    key_id = sys.argv[2]
    api_key = sys.argv[3]

    claims = {
        "sub": api_key,
        "iss": api_key,
        "jti": str(uuid.uuid4()),
        "aud": realm_url,
        "exp": int(time()) + 300,
    }

    with open(private_key_filename, "rb") as f:
        private_key = f.read()

    client_assertion = jwt.encode(
      claims, private_key, algorithm="RS512", headers={'kid': key_id}
    )

    token_response = requests.post(
        f"https://internal-dev.api.service.nhs.uk/oauth2/token",
        data={
            "grant_type": "client_credentials",
            "client_assertion_type": "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
            "client_assertion": client_assertion,
        },
    )

    response = token_response.json()
    access_token = response["access_token"]
    print(f"Access token: ${access_token}")

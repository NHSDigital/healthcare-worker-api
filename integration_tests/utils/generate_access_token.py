import os.path
import sys
import uuid
from time import time
import jwt
import requests


def generate_from_command_line():
    if len(sys.argv) != 2:
        print("Expected format poetry run start <api_key>")
        exit(1)

    client_id = sys.argv[1]
    access_token = generate_access_token(client_id)
    print(f"Access token: {access_token}")


def generate_access_token(client_id: str):
    realm_url = "https://internal-dev.api.service.nhs.uk/oauth2/token"

    # File not saved into git, it can be downloaded from AWS Secrets Manager "internal-dev/request-key" secret
    private_key_filename = f"{os.path.dirname(os.path.realpath(__file__))}/test-1.pem"
    key_id = "test-1"

    claims = {
        "sub": client_id,
        "iss": client_id,
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
    return access_token

from statistics import correlation
from uuid import uuid4

import requests

from config.current_env import get_current_env


class IntegrationTest:
    @staticmethod
    def send_request(access_token: str, path: str, params: dict = None):
        env = get_current_env()
        path = f"{env.base_url}/{path}"

        correlation_id = str(uuid4())
        headers = {
            "Authorization": f"Bearer {access_token}",
            "X-Correlation-ID": correlation_id
        }

        print(f"Sending request to {path} with correlation id {correlation_id}")
        return requests.get(
            path, params=params, headers=headers
        )

"""
Integration tests for the worker endpoint
"""
from typing import Optional

import pytest

from config.current_env import get_current_env
from utils.generate_access_token import generate_access_token
from utils.integration_test_base import IntegrationTest


class TestWorker(IntegrationTest):
    access_token: Optional[str]

    def send_worker_get(self, worker_id: Optional[int]):
        return self.send_request(self.access_token,"Worker", {"identifier": worker_id})

    @pytest.fixture(autouse=True)
    def resource(self):
        env = get_current_env()
        self.access_token = generate_access_token(env.client_id)

        yield

    def test_get_worker(self):
        response = self.send_worker_get(1)
        worker_details = response.json()

        assert response.status_code == 200
        assert worker_details == {"id": "1"}

    def test_get_worker_without_id(self):
        # Just for testing purposes this defaults to 123 if not provided
        response = self.send_worker_get(None)
        worker_details = response.json()

        assert response.status_code == 200
        assert worker_details == {"id": "111"}

    def test_get_missing_worker(self):
        # Just for testing purposes worker 999 is not found
        response = self.send_worker_get(999)
        worker_details = response.json()

        assert response.status_code == 404
        assert worker_details == {"error": "User not found"}

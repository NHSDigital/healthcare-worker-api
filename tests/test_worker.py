"""
Integration tests for the worker endpoint
"""
import pytest
import subprocess


@pytest.fixture
def resource():
    result = subprocess.call(["proxygen", "pytest-nhsd-apim", "get-token"])
    print(result)

    yield

    # tear down


def test_get():
    pass

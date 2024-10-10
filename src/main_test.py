from aws_lambda_powertools.utilities.typing import LambdaContext

from main import lambda_handler


def test_worker():
    response = lambda_handler({"resource": "/Worker"}, LambdaContext())

    assert response["statusCode"] == 200


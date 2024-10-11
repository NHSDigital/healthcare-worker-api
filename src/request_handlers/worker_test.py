from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

from request_handlers.worker import WorkerHandler


def test_worker_handler():
    handler = WorkerHandler()
    response = handler.get(APIGatewayProxyEvent(data={"resource": "/Worker"}))

    assert response.id == "111"

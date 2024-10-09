from typing import Dict, Type

from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

from fhir.worker import FhirWorker
from hcw_exception import HcwException
from request_handlers.base_handler import BaseHandler
from request_handlers.worker import WorkerHandler


handlers: Dict[str, Type[BaseHandler]]
handlers = {
    "/Worker": WorkerHandler
}


class UnknownHandler(HcwException):
    def __init__(self, endpoint):
        super().__init__(f"There is no defined handler for the provided endpoint {endpoint}")


def handle_event(endpoint: str, event: APIGatewayProxyEvent) -> FhirWorker:
    if endpoint not in handlers:
        raise UnknownHandler(endpoint)

    return handlers[endpoint]().get(event)


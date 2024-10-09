"""Handler for the worker endpoint"""
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

from fhir.worker import FhirWorker
from logs.log import Log
from request_handlers.base_handler import BaseHandler

logger = Log("worker_handler")


class WorkerHandler(BaseHandler):
    def get(self, event: APIGatewayProxyEvent) -> FhirWorker:
        logger.info("Creating stub 123 worker")
        worker = FhirWorker()
        worker.id = "123"
        return worker

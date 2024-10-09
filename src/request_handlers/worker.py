"""Handler for the worker endpoint"""
from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

from fhir.worker import FhirWorker
from hcw_exception import HcwException
from logs.log import Log
from request_handlers.base_handler import BaseHandler

logger = Log("worker_handler")


class WorkerHandler(BaseHandler):
    def get(self, event: APIGatewayProxyEvent) -> FhirWorker:
        worker_id = event.query_string_parameters.get("identifier")
        if worker_id == "999":
            raise HcwException(404, "User not found")
        elif worker_id is None:
            worker_id = "123"

        logger.info("Creating stub 123 worker")
        worker = FhirWorker()
        worker.id = worker_id
        return worker

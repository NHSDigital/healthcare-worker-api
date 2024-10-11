from abc import abstractmethod

from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

from fhir.worker import FhirWorker


class BaseHandler:
    @abstractmethod
    def get(self, event: APIGatewayProxyEvent) -> FhirWorker:
        pass

"""
Contains a log class to make logging easy and consistent. This ensures that the available logs are in cloudwatch
and that the logs are available when running locally.
"""
import logging
import sys

from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent

logging.basicConfig(level=logging.INFO, stream=sys.stdout)

correlation_id = None


class Log:
    module_name: str

    """
    Class with basic logging functions for different severities
    """
    def __init__(self, module_name: str):
        self.logger = logging.getLogger()
        self.module_name = module_name

    @staticmethod
    def save_event_details(event: APIGatewayProxyEvent):
        """
        Saves the correlation id from the request so we can use it in future logging calls
        :param event: Lambda event with details like correlation id
        """
        global correlation_id
        correlation_id = event.resolved_headers_field.get("X-Correlation-ID", None)

    @staticmethod
    def cleanup():
        """
        Called at the end of a request so that the log details from one request don't leak into another
        """
        global correlation_id
        correlation_id = None
        logging.shutdown()

    def info(self, message: str):
        """
        General purpose info logging for information that could be useful in developer logs.
        :param message: Message to be logged
        """
        log_message = f"Correlation-ID: {correlation_id}, {message}"
        self.logger.info(log_message)
        print(f"From PRINT: {log_message}")

    def error(self, message: str):
        """
        Logs an error message for tracking in developer logs and possibly alerting.
        :param message: Message to be logged
        """
        log_message = f"Correlation-ID: {correlation_id}, {message}"
        self.logger.error(log_message)
        print(f"From PRINT: {log_message}")

"""
Contains a log class to make logging easy and consistent. This ensures that the available logs are in cloudwatch (both
debug and audit logs) and that the logs are available when running locally.
"""
import logging
import sys


class Log:
    """
    Class with basic logging functions for different severities. Also allows for specific audit logging.
    """
    # Need to send these logs somewhere useful (i.e. cloudwatch) under HCW-98
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)

    def __init__(self, module_name):
        self.logger = logging.getLogger(module_name)

    def info(self, message: str):
        """
        General purpose info logging for information that could be useful in developer logs.
        :param message: Message to be logged
        """
        self.logger.info(message)
        print(f"INFO: {message}")

    def error(self, message: str):
        """
        Logs an error message for tracking in developer logs and possibly alerting.
        :param message: Message to be logged
        """
        self.logger.error(message)
        print(f"ERROR: {message}")

    def audit(self, message: str):
        """
        Logs an audit message for recording user actions.
        :param message: Message to be logged
        """
        raise NotImplementedError("Not implemented audit yet")

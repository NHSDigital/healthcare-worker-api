import logging
import sys


class Log:
    # TODO: Need to send these logs somewhere useful (i.e. cloudwatch)
    logging.basicConfig(level=logging.INFO, stream=sys.stdout)

    def __init__(self, module_name):
        self.logger = logging.getLogger(module_name)

    def info(self, message: str):
        self.logger.info(message)
        print(f"INFO: {message}")

    def error(self, message: str):
        self.logger.error(message)
        print(f"ERROR: {message}")

    def audit(self, message: str):
        raise NotImplementedError("Not implemented audit yet")

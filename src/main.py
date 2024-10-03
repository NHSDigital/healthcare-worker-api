"""
Basic hello world app for an initial deployment
"""
from greeting import greeting_message
from logs.log import Log

logger = Log("main")


def lambda_handler(event, context):
    logger.info(greeting_message())


def local_start():
    lambda_handler(None, None)


if __name__ == '__main__':
    local_start()

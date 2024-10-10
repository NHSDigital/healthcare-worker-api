"""
Basic hello world app for an initial deployment
"""
from greeting import greeting_message
from logs.log import Log

logger = Log("main")


# pylint: disable=unused-argument
def lambda_handler(event, context):
    """
    Lambda event handler
    :param event: Event info passed to the lambda for this execution
    :param context: General context info for the lambda
    :return:
    """
    logger.info(greeting_message())


def local_start():
    """
    This is just a helper function for triggering the lambda handler locally without having to provide the event
    and context objects
    """
    lambda_handler(None, None)


if __name__ == '__main__':
    local_start()

"""
Basic hello world app for an initial deployment
"""
from aws_lambda_powertools.utilities.typing import LambdaContext
from event_type import ApiGatewayEvent
from greeting import greeting_message
from logs.log import Log

logger = Log("main")


def lambda_handler(event_dict: dict, context: LambdaContext) -> dict:
    """
    Lambda event handler
    :param event_dict: Event info passed to the lambda for this execution
    :param context: General context info for the lambda
    :return:
    """
    logger.info(f"Received event: {event_dict} and context: {context}")

    event = ApiGatewayEvent(event_dict)
    logger.save_event_details(event)

    greeting = greeting_message()
    logger.info(greeting)
    return {
        "isBase64Encoded": False,
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": greeting
    }


def local_start():
    """
    This is just a helper function for triggering the lambda handler locally without having to provide the event
    and context objects
    """
    lambda_handler({}, LambdaContext())


if __name__ == '__main__':
    local_start()

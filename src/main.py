"""
Basic hello world app for an initial deployment
"""
import json

from aws_lambda_powertools.utilities.data_classes import APIGatewayProxyEvent
from aws_lambda_powertools.utilities.typing import LambdaContext

from hcw_exception import HcwException
from logs.log import Log
from request_handlers.handlers import handle_event

logger = Log("main")


def lambda_handler(event_dict: dict, context: LambdaContext) -> dict:
    """
    Lambda event handler
    :param event_dict: Event info passed to the lambda for this execution
    :param context: General context info for the lambda
    :return: The response to the API gateway, including response body it will forward on
    """
    event = APIGatewayProxyEvent(event_dict)
    logger.save_event_details(event)
    logger.info(f"Received event: {event} and context: {context}")

    try:
        response = handle_event(event.resource, event)

        full_response = {
            "isBase64Encoded": False,
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": response.to_json(),
        }
    except HcwException as e:
        logger.error(str(e))

        full_response = {
            "isBase64Encoded": False,
            "statusCode": e.status_code,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": e.return_message})
        }

    logger.info(f"Sending response of {full_response}")
    Log.cleanup()
    return full_response


def local_start():
    """
    This is just a helper function for triggering the lambda handler locally without having to provide the event
    and context objects
    """
    lambda_handler({"resource": "/Worker"}, LambdaContext())


if __name__ == '__main__':
    local_start()

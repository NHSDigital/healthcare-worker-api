"""
Just for state out module imports
"""
import boto3
from logs.log import Log

logger = Log("main")


def greeting_message() -> str:
    """
    Generates a greeting message
    :return: Greeting
    """
    logger.info(boto3.resource("s3"))
    return "Debug int deployment!"

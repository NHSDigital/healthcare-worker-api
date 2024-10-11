import os
from typing import Optional

from jproperties import Properties

from integration_tests.config.base_environment import EnvironmentConfig
from .ft_environment import FtEnvironmentConfig
from .pr_environment import PrEnvironmentConfig

default_env = ""


def get_from_config_file() -> Optional[tuple[str, str]]:
    configs = Properties()
    with open(f"{os.path.dirname(os.path.realpath(__file__))}/../locals.properties", "rb") as f:
        configs.load(f)

    env = configs.get("env")
    client_id = configs.get("client_id")

    if not env:
        return None

    return env.data.lower(), client_id.data if client_id else None


def get_from_environment_variables() -> Optional[tuple[str,str]]:
    env = os.getenv("TEST_ENV")
    client_id = os.getenv("TEST_CLIENT_ID")
    if not env:
        return None

    return env.lower(), client_id if client_id else None


def get_current_env() -> EnvironmentConfig:
    env_details = get_from_environment_variables() or get_from_config_file()
    if not env_details:
        message = "Environment needs to be specified as either an env variable or in locals.properties"
        raise Exception(message)

    env, client_id = env_details
    if env.lower().startswith("pr-"):
        return PrEnvironmentConfig(client_id, env)
    if env == "ft":
        return FtEnvironmentConfig()
    else:
        raise NotImplementedError("Unknown environment. Cannot run tests.")

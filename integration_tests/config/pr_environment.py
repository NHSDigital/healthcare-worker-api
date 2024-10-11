from integration_tests.config.base_environment import EnvironmentConfig


class PrEnvironmentConfig(EnvironmentConfig):
    def __init__(self, client_id: str, pr_env: str):
        if not client_id:
            raise Exception("Client id must be defined for PR environments")

        super(PrEnvironmentConfig, self).__init__(client_id)
        self.base_url = f"https://internal-dev.api.service.nhs.uk/healthcare-worker/{pr_env}"

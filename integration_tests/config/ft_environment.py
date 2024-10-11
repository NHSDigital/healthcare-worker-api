from integration_tests.config.base_environment import EnvironmentConfig


class FtEnvironmentConfig(EnvironmentConfig):
    client_id = "fdtMKRXX1MeMKTWVFdOAwVSpTM7mBTj6"

    def __init__(self):
        super(FtEnvironmentConfig, self).__init__(self.client_id)
        self.base_url = f"https://internal-dev.api.service.nhs.uk/healthcare-worker"

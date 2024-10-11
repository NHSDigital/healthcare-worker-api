from integration_tests.config.base_environment import EnvironmentConfig


class FtEnvironmentConfig(EnvironmentConfig):
    # TODO: Need to put the ft client id here once we have one. Remember to setup FT integration tests in the pipeline too!
    client_id = ""

    def __init__(self):
        super(FtEnvironmentConfig, self).__init__(self.client_id)
        self.base_url = f"https://internal-dev.api.service.nhs.uk/healthcare-worker"

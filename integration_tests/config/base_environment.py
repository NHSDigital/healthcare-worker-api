class EnvironmentConfig:
    client_id: str
    base_url: str

    def __init__(self, client_id: str):
        self.client_id = client_id

# There are more fields available in the event, this just lists the ones we're interested in
class ApiGatewayEvent:
    resource: str

    def __init__(self, event: dict):
        self.resource = event.get("resource")
        self.path = event.get("path")
        self.httpMethod = event.get("httpMethod")
        self.correlation_id = event.get("headers", {}).get("correlationId")


# There are more fields available in the event, this just lists the ones we're interested in
class RequestHeaders:
    x_correlation_id: str


class ApiGatewayEvent:
    resource: str
    path: str
    httpMethod: str
    requestContext: dict
    headers: RequestHeaders
    multiValueHeaders: dict
    queryStringParameters: dict



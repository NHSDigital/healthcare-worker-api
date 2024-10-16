import json
import boto3
import os

import urllib3


def get_github_access_token() -> str:
    secret_id = os.environ["secret_id"]
    client = boto3.client("secretsmanager")

    response = client.get_secret_value(SecretId=secret_id)
    return response["SecretString"]


def get_commit_details(message):
    codepipeline_client = boto3.client('codepipeline')
    response = codepipeline_client.get_pipeline_execution(
        pipelineName=message['detail']['pipeline'],
        pipelineExecutionId=message['detail']['execution-id']
    )
    print(response)
    commit_id = response['pipelineExecution']['artifactRevisions'][0]['revisionId']
    variables = response['pipelineExecution']['variables']
    branch = next(filter(lambda env: env["name"] == "branch", variables))

    return commit_id, branch


def build_status_update(message, state):
    url = (f"https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/{message['detail']['pipeline']}"
            f"/executions/{message['detail']['execution-id']}?region=eu-west-2")

    build_status = {
        'state': state,
        'context': 'HCW Deployment',
        'description': "CodePipeline: " + message['detail']['pipeline'],
        'target_url': url
    }

    print(build_status)
    return build_status


def send_status_update_request(commit_id, build_status):
    url = "https://api.github.com/repos/NHSDigital/healthcare-worker-api/statuses/" + commit_id

    print(f"Sending to URL {url}")
    http = urllib3.PoolManager()
    r = http.request('POST', url,
                        headers={'Content-Type': 'application/json',
                            'Authorization': f"Bearer {get_github_access_token()}"},
                        body=json.dumps(build_status).encode('utf-8')
                    )
    print(r.data)


def get_commit_state(message):
    stage = message["detail"]["stage"].upper()
    state = message['detail']['state'].upper()
    print(f"Checking with {stage} and {state}")

    if stage == "SOURCE" and state == "STARTED":
        # Means that the pipeline just started
        return "pending"

    if stage == "INTEGRATION-TEST" and state == "SUCCEEDED":
        # Means that integration tests have run successfully
        return "success"

    if state == "FAILED" or state == "STOPPED":
        return "error"


def handler(event, context):
    print(f"event = {event}, context = {context}")
    message = json.loads(event["Records"][0]["Sns"]["Message"])

    state = get_commit_state(message)

    if not state:
        # Means that we're not interested in this update
        return

    commit_id, branch = get_commit_details(message)
    build_status = build_status_update(message, state)
    send_status_update_request(commit_id, build_status)

    if branch == "ft":
        # Means that we're running the build from develop to deploy to ft
        print("Deploying to FT, in the future will insert logic here to publish updates to the team")

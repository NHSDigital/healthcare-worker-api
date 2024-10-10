# Healthcare Worker API

The Healthcare Worker API is a Python app deployed to AWS.

## Setup

Before performing any local development we need to perform some basic setup tasks.

### Python

This is a Python API with dependencies pulled in using poetry. In order to run locally you must have [Python](https://www.python.org/downloads/)
and [poetry](https://python-poetry.org/docs/) installed.

PyCharm is the recommended IDE for this project. When setting up for the first time we need to configure the Python
interpreter, which will also set up a virtual environment for our dependency installs. To set this up:

1. Open one of the Python files (under `src`) in PyCharm
2. Click the "Configure Python Interpreter" link in the top of the window
3. Select "Add New Interpreter" -> "Add Local Interpreter"
4. Leave the directory as the default (should be `venv` within the root of the project)
5. Ensure that the Python version is set to at Python 3.12
6. Check that the `venv` directory has been created and that the missing interpreter warning no longer displays

If you want to install/run from a terminal you will need to activate the venv in that terminal. The command for this
varies slightly based on OS.

MacOS: `source venv/bin/activate`
Windows: `.\venv\Scripts\activate.bat`

Once you've switched to the venv you can install dependencies with `poetry install`.

We can run the application locally with the command `poetry run start`

If you need to manually deploy your local app to an environment then you need to build it first. Run the `./scripts/build-app.sh` script
from the root directory to generate the zip file that needs to be uploaded. Then run `./scripts/deploy-app.sh` to publish to app
to the S3 artifact bucket.

### Terraform

The `infrastructure` directory contains everything needed to define an HCW AWS environment. Generally these changes should
be deployed out through our GitHub pipelines, but sometimes you may need to test / build / deploy locally. This section
guides through how to do that.

1. Install and set up the [proxygen-cli](https://pypi.org/project/proxygen-cli/). This allows us to deploy new APIM apps for our PRs and static environments.
2. Install and setup [yq](https://github.com/mikefarah/yq), which is used to make minor changes to the specification yaml in order to support API deployments (e.g. renaming the title to include the PR number)
3. Install the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) if you haven't already
4. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) if you haven't already
5. Save your AWS credentials
   1. Go to the [AWS account list](https://d-9c67018f89.awsapps.com/start/#/?tab=accounts) page in a browser
   2. Select the environment you want to deploy to
   3. Click on the "Access Keys" link
   4. Copy the environment variables and paste into your terminal. This should have set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`.
6. Go to the `instrastructure` directory
7. Run `terraform init`. You should see a message including the message "Terraform has been successfully initialized!"
8. Each AWS account can host multiple application environments (e.g. multiple dev environments in the dev account), but there are also some things that need to be common across the entire environment (e.g. IAM roles). To manage this we have different Terraform workspaces. Any Terraform plan / apply should be run within a workspace and the choice of workspace will depend on the change you want to deploy:
   1. `mgmt` for anything that's common across all environments. Note that this change will affect all environments in the given account
   2. Static environment names like (e.g. `ft`, `int`) should be reserved for deployment from the pipelines
   3. Anything else can be used to deploy a test environment. If running locally it's a good idea to have the workspace name include your name in some way.
9. Switch to the Terraform workspace you want with `terraform workspace select <workspace>`
   1. If this is the first deployment to this workspace then you will need to run `terraform workspace new <workspace>` first
10. Run `terraform plan -var-file=environments/dev.tfvars` to validate your changes and see what impact it will have if deployed
    1. This is important. **Make sure the plan represents the change you want to make before running the apply command**
11. If you're happy with the above plan, run `terraform apply -var-file=environments/dev.tfvars` to make the change in AWS
    1. If you're deploying to an app environment (i.e. not management) then you'll also need to specify location of the S3 lambda code in S3. For example, `-var "app_s3_filename=66374856c6c908c50e5d0974704b0e727106a934.zip"`. Since you need a valid zip file before deployments, it's almost always easier to let the update happen automatically through the PR.

In the future we plan to put the "management" resources into their own AWS account - [HCW-100](https://nhsd-jira.digital.nhs.uk/browse/HCW-100). For now, we have the `mgmt` workspace in dev which contains all the global resources and `mgmt-int` in int which contains build resources shared by int & ref.

A Terraform linter runs on each push to a PR, the command `terraform fmt -recursive` will resolve any simple formatting issues for fix that status failure.

## Environments & Pipelines

We have a number of dev environments and static environments for more formal testing. The following is our current environments, along with their AWS account and their general purpose:

* Dev environments - dev - created automatically with each PR
* FT - dev - created automatically from the latest code on the develop branch
* Sand - int - for supplier testing with minimal barriers, designed to return a representative response but not a true integration
* Int - int - for integration testing with suppliers
* Ref - int - for formal release testing before deploying to production
* Prod - prod - production environment

### Development process

#### PRs

**All commits need to be [signed](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)** else the PR will be automatically rejected.

All work should be performed against a ticket in the HCW jira project. The changes should be made on a branch specific to that ticket.
We don't have any formal branch naming conventions, but as a minimum the ticket number must be on the branch.
There is no restriction of commit names on the branch, but all PRs must be squashed when merging.
The squashed commit message should start with the jira ticket number and include a brief description of the change, (e.g. "HCW-76: Deployment Pipeline").

Creating a PR will automatically trigger a few different processes. The PR itself shows the status of a number of checks performed on the code.
This includes things like linting, Terraform format checks and spelling checker. It also automatically triggers the
deployment of the dev environment based on the PR. Note that there is currently no indication of the state of the deployment on the PR (see [HCW-101](https://nhsd-jira.digital.nhs.uk/browse/HCW-101)).

You can check on the status of your build and deployment through the AWS console in the dev account (note that this may change to the management account under [HCW-100](https://nhsd-jira.digital.nhs.uk/browse/HCW-100)).
The hcw-api-deployment pipeline will trigger within a minute of the PR creation (or new commit to an existing PR). The history page shows current and previous runs - see [AWS pipeline execution history page](https://eu-west-2.console.aws.amazon.com/codesuite/codepipeline/pipelines/hcw-api-deployment/executions) (you can use the "Source revisions" column to make sure you've found your build)

Each pipeline starts with the "build" which performs a poetry build to generate the files that will deployed to the lambda. The S3-Upload action then zips and uploads the files to S3, this ensures that future deployments will be deploying exactly the same code.
The "Deploy" action performs any relevant infrastructure changes, including updating the application lambda to the latest code. The dev environment is up to date once this step completes.

*Note that not all of the Terraform in the repository is applied at this stage. There are some resources which are common between environments, they are only updated once the PR is merged into develop. See above Terraform section for more information.*

#### Post Merge Process

The same pipeline (hcw-api-deployment) is triggered for merges to develop, but it deploys to "FT" instead of a PR dev environment. Once the deployment is complete it also triggers the "hcw-api-static-env-deployment" job.
The main difference is that this pipeline requires approval before every deployment, ensuring that we don't update a higher environment accidentally.
The deployments happen in other environments, so you'll need to log into the int or prod AWS accounts to see their logs, but the pipeline will show if the job ran successfully or not.

## Testing

The best way to test an environment is to use the integration tests in this repository. If you want to test against a branch
then you need to create a PR first. This deploys the application to AWS and APIM, which is where the integration tests run against.
The following steps describe how to set up and run these integration tests against any environment:

1. Make sure that you have the private key file at `integration_test/utils/test-1.pem`. This key is used to validate requests sent to APIM and so is needed for all requests, but it isn't checked into git for security. It can be downloaded from AWS Secret Manager `internal-dev/request-key` secret.
2. Modify the file at `integration_tests/locals.properties` based on the environment you're testing
   1. If you're testing a PR environment then you need to populate the `env` (e.g. `pr-16`) and `client_id` values. The `client_id` can be found in the deploy job output (`Client id = <client_id>`)
   2. If you're testing a static environment (e.g. ft) then you only need to put the environment name into the `env` field
3. From the repository root make sure you've run a `poetry install` for any dependencies needed by the tests
4. You can now run all integration tests from the command line by going to the `integration_tests` directory and running `pytest`
   1. Note that running from the repository root does not trigger the integration tests, this is to separate them from the unit tests for normal running
   2. You can also run individual tests from inside IDEs like pycharm

### Manual testing

The current pipeline will automatically create APIM apps, and the integration tests handle authentication automatically.
Before this was available we had to go through those steps manually. While this shouldn't be necessary now, it's useful to
keep the process documented. This section lists the steps required to create an APIM app and send manual requests through
postman. It assumes that there is already an environment in AWS to point to, and an API product in APIM.

1. Before starting, check the PR number of your raised PR. This is the number at the end of the PR URL, it also displays in the title after the #.
2. Connect to the HSCN VPN
3. Go to `https://dos-dev.ptl.api.platform.nhs.uk/` and login. You can create a dev account through the UI if you haven't already.
4. Click on "Environment Access"
5. Click "Add new application"
6. Select "Development"
7. Select "Me"
8. Enter an application name like "HCW PR-<pr_number>" and click "Continue"
9. Select "Create Application"
10. Select "View your new application"
11. On the "Public key URL" line click "Edit"
12. Enter the URL of `https://raw.githubusercontent.com/NHSDigital/identity-service-jwks/refs/heads/main/jwks/internal-dev/5eef95c7-031c-4d7b-ab58-1fee6e91a915.json`, this related to a known key pair so we can generate valid requests using it.
13. Select "Save" and then once confirmed click on your app name in the top breadcrumbs to return to the previous page
14. Select "Add APIs"
15. Search for PR-<pr_number> to find your app instance. Note that there are other projects in this space, so make sure you've selected a healthcare worker API
16. Select your PR and click "Save"
17. On the "Active API keys" line click "Edit"
18. Make note of the key shown on this page as it's needed to generate valid requests

With the above steps you have created a valid APIM app which will route requests to your PR. We can now start sending
requests through to the HCW APIs. In order for these requests to be successful we need to authenticate with APIM using
an access token. This repository includes a script for generating a valid access token based on the above keypair.

1. Make sure that you have the private key at `integration_tests/utils/test-1.pem`. This file is not checked into git for security. It can be downloaded from AWS Secret Manager `internal-dev/request-key` secret.
2. Install the poetry dependencies from the top level if you haven't already: `poetry install`
3. Run the script with the following command, replacing `<api_key>` with the API key from your app: `poetry run token <api_key>`
4. The script will output the access token. This needs to be included in any requests in the `Authorization` header as `Bearer <access_token>`

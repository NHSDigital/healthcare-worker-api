# Healthcare Worker API

The Healthcare Worker API is a Python app deployed to AWS.

## Setup

Before performing any local development we need to perform some basic setup tasks.

## Python

This is a Python API with dependencies pulled in using poetry. In order to run locally you must have [Python](https://www.python.org/downloads/)
and [poetry](https://python-poetry.org/docs/) installed.

PyCharm is the recommended IDE for this project. When setting up for the first time we need to configure the Python
interpreter, which will also set up a virtual environment for our dependency installs. To set this up:

1. Open one of the Python files (under `src`) in PyCharm
2. Click the "Configure Python Interpreter" link in the top of the window
3. Select "Add New Interpreter" -> "Add Local Interpreter"
4. Leave the directory as the default (should be `venv` within the root of the project)
5. Ensure that the Python version is set to at Python 3.10
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

## Terraform

The `infrastructure` directory contains everything needed to define an HCW AWS environment. Generally these changes should
be deployed out through our GitHub pipelines, but sometimes you may need to test / build / deploy locally. This section
guides through how to do that.

1. Install the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) if you haven't already
2. Install the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) if you haven't already
3. Save your AWS credentials
   1. Go to the [AWS account list](https://d-9c67018f89.awsapps.com/start/#/?tab=accounts) page in a browser
   2. Select the environment you want to deploy to
   3. Click on the "Access Keys" link
   4. Copy the environment variables and paste into your terminal. This should have set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` and `AWS_SESSION_TOKEN`.
4. Go to the `instrastructure` directory
5. Run `terraform init`. You should see a message including the message "Terraform has been successfully initialized!"
6. Each AWS account can host multiple application environments (e.g. multiple dev environments in the dev account), but there are also some things that need to be common across the entire environment (e.g. IAM roles). To manage this we have different Terraform workspaces. Any Terraform plan / apply should be run within a workspace and the choice of workspace will depend on the change you want to deploy:
   1. `mgmt` for anything that's common across all environments. Note that this change will affect all environments in the given account. This generally **not** what you want
   2. Static environment names like (e.g. `ft`, `int`) should be reserved for deployment from the pipelines
   3. Anything else can be used to deploy a test environment. If running locally it's a good idea to have the workspace name include your name in some way.
7. Switch to the Terraform workspace you want with `terraform workspace select <workspace>`
   1. If this is the first deployment to this workspace then you will need to run `terraform workspace new <workspace>` first
8. Run `terraform plan -var-file=environments/dev.tfvars` to validate your changes and see what impact it will have if deployed
   1. This is important. **Make sure the plan represents the change you want to make before running the apply command**
9. If you're happy with the above plan, run `terraform apply -var-file=environments/dev.tfvars` to make the change in AWS

#!/bin/bash

set -e

environment_name=$1
apim_environment=$2
apim_private_key_secret_arn=$3
api_gw_url=$4

cp ../specification/healthcare-worker-api.yaml temp_spec.yaml

yq -i ".x-nhsd-apim.target.url = \"${api_gw_url}\"" temp_spec.yaml
if [[ "$environment_name" == pr-* ]]; then
  uppercase_env_name=$(echo "$environment_name" | tr '[:lower:]' '[:upper:]')
  yq -i ".info.title = \"[${uppercase_env_name}] Healthcare Worker API\"" temp_spec.yaml
  env_name_suffix="_${environment_name}"
  echo "Set env name suffix to ${env_name_suffix}"
else
  env_name_suffix=""
  echo "No name suffix set"
fi

source ./modules/hcw-api/proxygen-setup.sh "$apim_private_key_secret_arn"

# Deploy proxygen instance
service_base_path="healthcare-worker${env_name_suffix}"
echo proxygen instance deploy --no-confirm "$apim_environment" "${service_base_path}" ./temp_spec.yaml
proxygen instance deploy --no-confirm "$apim_environment" "${service_base_path}" ./temp_spec.yaml

if [[ "$environment_name" == pr-* ]]; then
  echo "Creating APIM proxy app for new PR env"
  access_token=$(proxygen pytest-nhsd-apim get-token | jq -r ".pytest_nhsd_apim_token")

  existing_app_details=$(curl --location "https://api.enterprise.apigee.com/v1/organizations/nhsd-nonprod/developers/ian.robinson27@nhs.net/apps/${service_base_path}" \
    --header "Authorization: Bearer ${access_token}" \
    --header 'Content-Type: application/json')
  existing_app_id=$(echo "$existing_app_details" | jq -r ".appId")

  if [[ "$existing_app_id" != "null" ]]; then
    echo "App already created, checking if the api product is still linked"
    api_product=$(echo "$existing_app_details" | jq -r ".credentials[0].apiProducts")
    if [[ "$api_product" == "[]" ]]; then
        echo "The API product has been removed, so we need to remove and re-create the app"
        curl --location "https://api.enterprise.apigee.com/v1/organizations/nhsd-nonprod/developers/ian.robinson27@nhs.net/apps/${service_base_path}" \
        --header "Authorization: Bearer ${access_token}" \
        -X DELETE

        existing_app_id="null" # Marks the API to be re-created below
    fi
  fi

  if [[ "$existing_app_id" == "null" ]]; then
    echo "Creating new Apigee app"
    api_body="{
          \"apiProducts\": [
              \"healthcare-worker-api--internal-dev--${service_base_path}--app-level3\"
          ],
          \"attributes\": [
              {
                  \"name\": \"DisplayName\",
                  \"value\": \"${service_base_path}\"
              },
              {
                  \"name\": \"environment\",
                  \"value\": \"internal-dev\"
              },
              {
                  \"name\": \"jwks-resource-url\",
                  \"value\": \"https://raw.githubusercontent.com/NHSDigital/identity-service-jwks/refs/heads/main/jwks/internal-dev/5eef95c7-031c-4d7b-ab58-1fee6e91a915.json\"
              }
          ],
          \"name\": \"${service_base_path}\",
          \"scopes\": [],
          \"status\": \"approved\"
      }"

    # It appears that apigee's API has a limitation which doesn't allow us to register apps to a team through the API:
    # see https://apidocs.apigee.com/apis?search=apps and https://apidocs.apigee.com/docs/developer-apps/1/overview
    # The choice of user shouldn't make any difference since we don't need to modify it, but it's obviously not ideal
    # to link to an individual.
    app_details=$(curl --location 'https://api.enterprise.apigee.com/v1/organizations/nhsd-nonprod/developers/ian.robinson27@nhs.net/apps' \
      --header "Authorization: Bearer ${access_token}" \
      --header 'Content-Type: application/json' \
      --data "$api_body")

    echo "App creation request sent:"
    echo "$app_details"

    env_app_client_id=$(echo "$app_details" | jq -r ".credentials[0].consumerKey")
    echo "Generated client id = ${env_app_client_id}"
  fi
fi


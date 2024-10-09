#!/bin/bash

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
else
  env_name_suffix=""
fi

#Proxygen settings
proxygen settings set api "healthcare-worker-api"
proxygen settings set endpoint_url "https://proxygen.prod.api.platform.nhs.uk"
proxygen settings set spec_output_format "yaml"

# Get proxygen private key to allow for proxy instance deployment
aws secretsmanager get-secret-value --secret-id "$apim_private_key_secret_arn" | jq -r ".SecretString" > ~/proxygen_private_key.pem
proxygen credentials set private_key_path ~/proxygen_private_key.pem key_id key-1 client_id healthcare-worker-api-client

# Deploy proxygen isntance
proxygen instance deploy --no-confirm "$apim_environment" "healthcare-worker${env_name_suffix}" ./temp_spec.yaml
rm ~/proxygen_private_key.pem


#!/bin/bash

environment_name=$1
apim_environment=$2
apim_private_key_secret_arn=$3


if [[ "$environment_name" == pr-* ]]; then
  env_name_suffix="_${environment_name}"
  echo "Set env name suffix to ${env_name_suffix}"
else
  env_name_suffix=""
  echo "No name suffix set"
fi

source ./modules/hcw-api/proxygen-setup.sh "$apim_private_key_secret_arn"

# Deploy proxygen instance
echo proxygen instance delete --no-confirm "$apim_environment" "healthcare-worker${env_name_suffix}"
proxygen instance delete --no-confirm "$apim_environment" "healthcare-worker${env_name_suffix}"

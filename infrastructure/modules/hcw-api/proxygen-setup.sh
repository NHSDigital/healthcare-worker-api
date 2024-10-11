#!/bin/bash

apim_private_key_secret_arn=$1

yes "" | proxygen credentials set
proxygen settings set api "healthcare-worker-api"
proxygen settings set endpoint_url "https://proxygen.prod.api.platform.nhs.uk"
proxygen settings set spec_output_format "yaml"

# Get proxygen private key to allow for proxy instance deployment
aws secretsmanager get-secret-value --secret-id "$apim_private_key_secret_arn" | jq -r ".SecretString" > /tmp/proxygen_private_key.pem
ls /tmp/proxygen_private_key.pem
proxygen credentials set private_key_path /tmp/proxygen_private_key.pem key_id key-1 client_id healthcare-worker-api-client

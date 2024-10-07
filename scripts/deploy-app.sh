#!/bin/bash

if [ $# -eq 0 ]; then
  echo "One input argument expected with the account name to deploy to (e.g. \"$0 dev\")"
  exit 1
fi

account=$1

build_id="$(date '+%Y-%m-%d')_$(uuidgen)"

aws s3 cp hcw-api.zip "s3://nhse-iam-hcw-build-artifacts-dev/${build_id}.zip"

echo "Deployed artifact with name ${build_id}"

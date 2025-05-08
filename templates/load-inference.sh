#!/bin/bash

set -eux

SYSTEM_CATALOG_PROJECT="system-catalog"


# CHANGE THIS
ENDPOINT="console.ncpqe-testbed.dev.rafay-edge.net"

# ORG Admin key
API_KEY="<rafay-api-key>"
if [ -z "${API_KEY}" ]
then
    echo "Please set the API_KEY environment variable"
    exit 1
fi

ORG_ID="<org-id>" # org id where the system catalog project is created
if [ -z "${ORG_ID}" ]
then
    echo "Please set the ORG_ID environment variable"
    exit 1
fi


# Create new resource template for inference-vllm-custom-model
curl -k -X 'POST' \
    -H "X-API-KEY: ${API_KEY}" \
    -H "X-ORGANIZATION-ID: ${ORG_ID}" \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    "https://${ENDPOINT}/apis/eaas.envmgmt.io/v1/projects/${SYSTEM_CATALOG_PROJECT}/resourcetemplates" \
    -d @./rt/inference-vllm-custom-model.json


# Create a new environment template for inference-vllm-custom-model
curl -k -X 'POST' \
    -H "X-API-KEY: ${API_KEY}" \
    -H "X-ORGANIZATION-ID: ${ORG_ID}" \
    -H 'Content-Type: application/json' \
    -H 'accept: application/json' \
    "https://${ENDPOINT}/apis/eaas.envmgmt.io/v1/projects/${SYSTEM_CATALOG_PROJECT}/environmenttemplates" \
    -d @./et/inference-vllm-custom-model.json

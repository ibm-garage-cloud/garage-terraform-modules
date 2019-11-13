#!/usr/bin/env bash

RESOURCE_GROUP="$1"
REGION="$2"

# The name of a registry namespace cannot contain uppercase characters
# Lowercase the resource group name, just in case...
REGISTRY_NAMESPACE=$(echo "$RESOURCE_GROUP" | tr '[:upper:]' '[:lower:]')

ibmcloud login --apikey "${APIKEY}" -g "${RESOURCE_GROUP}" -r "${REGION}" 1> /dev/null 2> /dev/null
if [[ $? -ne 0 ]]; then
  echo "Error logging into ibmcloud"
  exit 1
fi

echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
NS=$(ibmcloud cr namespaces | grep "${REGISTRY_NAMESPACE}" ||: )
if [[ -z "${NS}" ]]; then
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
    ibmcloud cr namespace-add "${REGISTRY_NAMESPACE}"
else
    echo -e "Registry namespace ${REGISTRY_NAMESPACE} found."
fi

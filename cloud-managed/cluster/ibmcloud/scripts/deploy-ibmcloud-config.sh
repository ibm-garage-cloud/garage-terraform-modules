#!/usr/bin/env bash

CHART="$1"
NAMESPACE="$2"
APIKEY="$3"
RESOURCE_GROUP="$4"
SERVER_URL="$5"
CLUSTER_TYPE="$6"
CLUSTER_NAME="$7"
INGRESS_SUBDOMAIN="$8"
REGION="$9"
REGISTRY_URL="${10}"
TLS_SECRET_NAME="${11}"
CLUSTER_VERSION="${12}"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    echo "Setting up KUBECONFIG=${KUBECONFIG_IKS}"
    cat "${KUBECONFIG_IKS}"
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi

if [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  CLUSTER_TYPE="openshift"
fi

NAME="ibmcloud-config"
OUTPUT_YAML="${TMP_DIR}/ibmcloud-apikey.yaml"

kubectl delete -n "${NAMESPACE}" secrets/ibmcloud-apikey
kubectl delete -n "${NAMESPACE}" configmaps/ibmcloud-config

ibmcloud login --apikey "${APIKEY}" -g "${RESOURCE_GROUP}" -r "${REGION}" 1> /dev/null 2> /dev/null
if [[ $? -ne 0 ]]; then
  echo "Error logging into ibmcloud"
  exit 1
fi

echo "*** Generating kube yaml from helm template into ${OUTPUT_YAML}"
helm init --client-only
mkdir -p "${TMP_DIR}"
helm template "${CHART}" \
    --name "${NAME}" \
    --namespace "${NAMESPACE}" \
    --set apikey="${APIKEY}" \
    --set resource_group="${RESOURCE_GROUP}" \
    --set server_url="${SERVER_URL}" \
    --set cluster_type="${CLUSTER_TYPE}" \
    --set cluster_name="${CLUSTER_NAME}" \
    --set tls_secret_name="${TLS_SECRET_NAME}" \
    --set ingress_subdomain="${INGRESS_SUBDOMAIN}" \
    --set region="${REGION}" \
    --set registry_url="${REGISTRY_URL}" > "${OUTPUT_YAML}" \
    --set cluster_version="${CLUSTER_VERSION}"

echo "*** Applying kube yaml ${OUTPUT_YAML}"
kubectl create -n "${NAMESPACE}" -f "${OUTPUT_YAML}"

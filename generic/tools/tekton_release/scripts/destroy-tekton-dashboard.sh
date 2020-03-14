#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

NAMESPACE="$1"
DASHBOARD_VERSION="$2"
CLUSTER_TYPE="$3"
DASHBOARD_YAML_FILE_K8S="$4"
DASHBOARD_YAML_FILE_OCP="$5"


if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  DASHBOARD_YAML_FILE="${DASHBOARD_YAML_FILE_K8S}"
  CHART_NAME="tekton-config"
elif
  DASHBOARD_YAML_FILE="${DASHBOARD_YAML_FILE_OCP}"
  CHART_NAME="tekton-config-ocp"
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=./tmp
fi

mkdir -p ${TMP_DIR}
YAML_OUTPUT=${TMP_DIR}/tekton-config.yaml

# uninstall the tekton dashboard
kubectl delete -n "${NAMESPACE}" --filename https://github.com/tektoncd/dashboard/releases/download/${DASHBOARD_VERSION}/${DASHBOARD_YAML_FILE} || true

# installs the ingress, secret, and configmap
helm template "${CHART_DIR}/${CHART_NAME}" \
    --name "tekton" \
    --namespace "${NAMESPACE}" \
    --set name="tekton" > ${YAML_OUTPUT}
kubectl delete --namespace "${NAMESPACE}" -f ${YAML_OUTPUT} || true

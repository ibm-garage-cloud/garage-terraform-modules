#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

INGRESS_HOST="$1"
NAMESPACE="$2"
DASHBOARD_VERSION="$3"

URL="http://${INGRESS_HOST}"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=./tmp
fi

mkdir -p ${TMP_DIR}
YAML_OUTPUT=${TMP_DIR}/tekton-config.yaml

# installs the tekton dashboard
# note: The namespace is hardcoded in the dashboard-latest-release file
kubectl create namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || true
kubectl apply -n "${NAMESPACE}" --filename https://github.com/tektoncd/dashboard/releases/download/${DASHBOARD_VERSION}/dashboard-latest-release.yaml

# installs the ingress, secret, and configmap
helm template "${CHART_DIR}/tekton-config" \
    --name "tekton" \
    --namespace "${NAMESPACE}" \
    --set name="tekton" \
    --set hostname="${INGRESS_HOST}" \
    --set url="${URL}" > ${YAML_OUTPUT}
kubectl apply --namespace "${NAMESPACE}" -f ${YAML_OUTPUT}

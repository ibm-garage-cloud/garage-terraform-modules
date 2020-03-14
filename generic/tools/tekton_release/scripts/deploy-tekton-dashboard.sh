#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)


NAMESPACE="$1"
DASHBOARD_VERSION="$2"
CLUSTER_TYPE="$3"
DASHBOARD_YAML_FILE_K8S="$4"
DASHBOARD_YAML_FILE_OCP="$5"
DASHBOARD_HOST="$6"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  DASHBOARD_YAML_FILE="${DASHBOARD_YAML_FILE_K8S}"
else
  DASHBOARD_YAML_FILE="${DASHBOARD_YAML_FILE_OCP}"
fi


if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=./tmp
fi

mkdir -p ${TMP_DIR}
YAML_OUTPUT=${TMP_DIR}/tekton-config.yaml

# installs the tekton dashboard
# note: The namespace is hardcoded in the dashboard-latest-release file
kubectl create namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || true
kubectl apply -n "${NAMESPACE}" --filename https://github.com/tektoncd/dashboard/releases/download/${DASHBOARD_VERSION}/${DASHBOARD_YAML_FILE}


if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then

  URL="http://${DASHBOARD_HOST}"
  CHART_NAME="tekton-config"

else

  until [[ $(kubectl get route tekton-dashboard -n ${NAMESPACE} -o jsonpath='{.spec.host}') ]]
  do
      echo '>>> waiting for Tekton Dashboard Route availability'
      sleep 15
  done
  DASHBOARD_HOST=$(kubectl get route tekton-dashboard -n ${NAMESPACE} -o jsonpath='{.spec.host}')
  URL="https://${DASHBOARD_HOST}"
  CHART_NAME="tekton-config-ocp"
  
fi
# installs the ingress, secret, and configmap
helm template "${CHART_DIR}/${CHART_NAME}" \
    --name "tekton" \
    --namespace "${NAMESPACE}" \
    --set name="tekton" \
    --set hostname="${DASHBOARD_HOST}" \
    --set url="${URL}" > ${YAML_OUTPUT}
kubectl apply --namespace "${NAMESPACE}" -f ${YAML_OUTPUT}

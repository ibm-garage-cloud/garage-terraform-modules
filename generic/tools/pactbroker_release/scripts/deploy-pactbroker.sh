#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CHART="$1"
NAMESPACE="$2"
INGRESS_HOST="$3"
DATABASE_TYPE="$4"
DATABASE_NAME="$5"
TLS_SECRET_NAME="$6"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi

NAME="pact-broker"
OUTPUT_YAML="${TMP_DIR}/pactbroker.yaml"
SECRET_OUTPUT_YAML="${TMP_DIR}/pactbroker-secret.yaml"

mkdir -p ${TMP_DIR}

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  VALUES=ingress.hosts.0.host=${INGRESS_HOST}
  if [[ -n "${TLS_SECRET_NAME}" ]]; then
    VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
    VALUES="${VALUES},ingress.tls[0].hosts[0]=${INGRESS_HOST}"
    VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"
  fi
else
  VALUES="ingress.enabled=false,route.enabled=true"
fi

echo "*** Generating kube yaml from helm template into ${OUTPUT_YAML}"
helm3 template ${NAME} "${CHART}" \
    --namespace "${NAMESPACE}" \
    --set "${VALUES}" \
    --set database.type="${DATABASE_TYPE}" \
    --set database.name="${DATABASE_NAME}" > ${OUTPUT_YAML}

echo "*** Applying kube yaml ${OUTPUT_YAML}"
kubectl apply -n ${NAMESPACE} -f ${OUTPUT_YAML} --validate=false

if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5
  PACTBROKER_HOST=$(oc get route pact-broker -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  URL="https://${PACTBROKER_HOST}"
else
  PACTBROKER_HOST=$(kubectl get ingress/pact-broker -n "${NAMESPACE}" -o jsonpath='{ .spec.rules[0].host }')

  if [[ -n "${TLS_SECRET_NAME}" ]]; then
    URL="https://${PACTBROKER_HOST}"
  else
    URL="http://${PACTBROKER_HOST}"
  fi
fi


helm3 repo add toolkit-charts https://ibm-garage-cloud.github.io/toolkit-charts/
helm3 template pactbroker-config toolkit-charts/tool-config \
  --namespace "${NAMESPACE}" \
  --set name=pactbroker \
  --set url="${URL}" > "${SECRET_OUTPUT_YAML}"

kubectl apply -n "${NAMESPACE}" -f "${SECRET_OUTPUT_YAML}"

echo "*** Waiting for Pact Broker"
"${SCRIPT_DIR}/waitForEndpoint.sh" "${URL}" 150 12

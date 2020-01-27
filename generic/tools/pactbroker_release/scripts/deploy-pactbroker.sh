#!/usr/bin/env bash

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

mkdir -p ${TMP_DIR}

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  VALUES=ingress.hosts.0.host=${INGRESS_HOST}
  if [[ -n "${TLS_SECRET_NAME}" ]]; then
    VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
    VALUES="${VALUES},ingress.tls[0].hosts[0]=${INGRESS_HOST}"
    VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"
  fi
else
  VALUES="ingress.enable=false,route.enabled=true"
fi

echo "*** Generating kube yaml from helm template into ${OUTPUT_YAML}"
helm init --client-only
helm template ${CHART} \
    --namespace ${NAMESPACE} \
    --name ${NAME} \
    --set "${VALUES}" \
    --set database.type=${DATABASE_TYPE} \
    --set database.name=${DATABASE_NAME} > ${OUTPUT_YAML}

echo "*** Applying kube yaml ${OUTPUT_YAML}"
kubectl apply -n ${NAMESPACE} -f ${OUTPUT_YAML}

if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5
  PACTBROKER_HOST=$(oc get route pactbroker -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  npm i -g @garage-catalyst/ibm-garage-cloud-cli
  igc tools-config --name pactbroker --url "https://${PACTBROKER_HOST}"
fi

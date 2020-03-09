#!/usr/bin/env bash
# Sample usage :
# ./deploy-dashboard.sh tools openshift dashboard gsi-learning-ocp311-clu-7ec5d722a0ab3f463fdc90eeb94dbc70-0000.eu-gb.containers.appdomain.cloud dev

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

NAMESPACE="$1"
CLUSTER_TYPE="$2"
INGRESS_HOST="$3"
INGRESS_SUBDOMAIN="$4"
IMAGE_TAG="$5"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi

if [[ -z "${IMAGE_TAG}" ]]; then
    IMAGE_TAG="latest"
fi

CHART="${MODULE_DIR}/charts/developer-dashboard"
CONFIG_CHART="${MODULE_DIR}/charts/dashboard-config"

NAME="developer-dashboard"
OUTPUT_YAML="${TMP_DIR}/developerdashboard.yaml"
CONFIG_OUTPUT_YAML="${TMP_DIR}/developerdashboard-config.yaml"

CONFIG_MAP_YAML=$(echo "${CONFIG_MAPS}" | sed -E "s/[[](.+)[]]/{\1}/g" | sed "s/[[][]]//g")

mkdir -p ${TMP_DIR}

DASHBOARD_URL="http://${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"

VALUES="ingress.hosts.0=${INGRESS_HOST}"
if [[ -n "${TLS_SECRET_NAME}" ]]; then
    VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
    VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"

    DASHBOARD_URL="https://${INGRESS_HOST}.${INGRESS_SUBDOMAIN}"
fi

echo "*** Generating kube yaml from helm template into ${OUTPUT_YAML}"
#helm init --client-only
helm3 template "${NAME}" "${CHART}" \
    --namespace "${NAMESPACE}" \
    --set "clusterType=${CLUSTER_TYPE}" \
    --set "host=${INGRESS_HOST}" \
    --set "ingressSubdomain=${INGRESS_SUBDOMAIN}" \
    --set "image.tag=${IMAGE_TAG}" \
    --set "${VALUES}" \
    --set configMaps="${CONFIG_MAP_YAML}" > ${OUTPUT_YAML}

echo "*** Applying kube yaml ${OUTPUT_YAML}"
if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  kubectl apply -n "${NAMESPACE}" -f ${OUTPUT_YAML}
else
  oc apply -n "${NAMESPACE}" -f ${OUTPUT_YAML}
  DASHBOARD_HOST=$(oc get route "dashboard" -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')
  DASHBOARD_URL="https://${DASHBOARD_HOST}"
fi

helm3 template "${NAME}" "${CONFIG_CHART}" \
    --namespace "${NAMESPACE}" \
    --set url="${DASHBOARD_URL}" > ${CONFIG_OUTPUT_YAML}
kubectl apply -n "${NAMESPACE}" -f ${CONFIG_OUTPUT_YAML}

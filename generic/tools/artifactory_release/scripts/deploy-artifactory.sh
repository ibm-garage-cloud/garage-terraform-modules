#!/usr/bin/env bash

SCRIPT_DIR="$(cd $(dirname $0); pwd -P)"
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)
LOCAL_CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)
LOCAL_KUSTOMIZE_DIR=$(cd "${SCRIPT_DIR}/../kustomize"; pwd -P)

NAMESPACE="$1"
INGRESS_HOST="$2"
VALUES_FILE="$3"
CHART_VERSION="$4"
SERVICE_ACCOUNT_NAME="$5"
TLS_SECRET_NAME="$6"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi
if [[ -z "${CHART_REPO}" ]]; then
    CHART_REPO="https://charts.jfrog.io"
fi

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"


KUSTOMIZE_TEMPLATE="${LOCAL_KUSTOMIZE_DIR}/artifactory"

ARTIFACTORY_CHART="${CHART_DIR}/artifactory"
SECRET_CHART="${LOCAL_CHART_DIR}/artifactory-access"

ARTIFACTORY_KUSTOMIZE="${KUSTOMIZE_DIR}/artifactory"


NAME="artifactory"
ARTIFACTORY_OUTPUT_YAML="${ARTIFACTORY_KUSTOMIZE}/base.yaml"

CONFIG_VALUES_FILE="${MODULE_DIR}/artifactory-config-values.yaml"
OUTPUT_YAML="${TMP_DIR}/artifactory.yaml"
SECRET_OUTPUT_YAML="${TMP_DIR}/artifactory-secret.yaml"

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Fetching helm chart artifactory:${CHART_VERSION} from ${CHART_REPO}"
#mkdir -p ${CHART_DIR}
#helm init --client-only
#helm fetch --repo "${CHART_REPO}" --untar --untardir "${CHART_DIR}" --version "${CHART_VERSION}" artifactory

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  VALUES="ingress.hosts.0=${INGRESS_HOST}"
  if [[ -n "${TLS_SECRET_NAME}" ]]; then
      VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
      VALUES="${VALUES},ingress.tls[0].hosts[0]=${INGRESS_HOST}"
      VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"
  fi
else
  VALUES="ingress.enabled=false"
fi

helm3 repo add artifactory-repo ${CHART_REPO}

echo "*** Generating kube yaml from helm template into ${ARTIFACTORY_OUTPUT_YAML}"
helm3 template artifactory artifactory-repo/artifactory \
    --namespace "${NAMESPACE}" \
    --set "${VALUES}" \
    --set artifactory.persistence.storageClass="${STORAGE_CLASS}" \
    --values "${VALUES_FILE}" > "${ARTIFACTORY_OUTPUT_YAML}"

if [[ -n "${TLS_SECRET_NAME}" ]]; then
    URL="https://${INGRESS_HOST}"
else
    URL="http://${INGRESS_HOST}"
fi

echo "*** Building final kube yaml from kustomize into ${OUTPUT_YAML}"
kustomize build "${ARTIFACTORY_KUSTOMIZE}" > "${OUTPUT_YAML}"

echo "*** Applying kube yaml ${ARTIFACTORY_OUTPUT_YAML}"
kubectl apply -n "${NAMESPACE}" -f "${OUTPUT_YAML}"

if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5

  oc project "${NAMESPACE}"
  oc create route edge artifactory --service=artifactory-artifactory --insecure-policy=Redirect

  ARTIFACTORY_HOST=$(oc get route artifactory -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  URL="https://${ARTIFACTORY_HOST}"
fi

helm3 repo add toolkit-charts https://ibm-garage-cloud.github.io/toolkit-charts/
helm3 template artifactory-config toolkit-charts/tool-config \
  --namespace "${NAMESPACE}" \
  --set url="${URL}" \
  --values "${CONFIG_VALUES_FILE}" > "${SECRET_OUTPUT_YAML}"

kubectl apply -n "${NAMESPACE}" -f "${SECRET_OUTPUT_YAML}"

"${SCRIPT_DIR}/waitForEndpoint.sh" "${URL}" 150 12
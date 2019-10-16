#!/usr/bin/env bash

SCRIPT_DIR="$(cd $(dirname $0); pwd -P)"
LOCAL_CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)
LOCAL_KUSTOMIZE_DIR=$(cd "${SCRIPT_DIR}/../kustomize"; pwd -P)

NAMESPACE="$1"
INGRESS_HOST="$2"
VALUES_FILE="$3"
SERVICE_ACCOUNT_NAME="$4"
TLS_SECRET_NAME="$5"

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
SECRET_OUTPUT_YAML="${ARTIFACTORY_KUSTOMIZE}/secret.yaml"

OUTPUT_YAML="${TMP_DIR}/artifactory.yaml"

oc create serviceaccount -n ${NAMESPACE} artifactory
oc adm policy add-scc-to-user privileged -n ${NAMESPACE} -z artifactory

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Fetching helm chart from ${CHART_REPO}"
mkdir -p ${CHART_DIR}
helm init --client-only
helm fetch --repo "${CHART_REPO}" --untar --untardir "${CHART_DIR}" artifactory

VALUES="ingress.hosts.0=${INGRESS_HOST}"
if [[ -n "${TLS_SECRET_NAME}" ]]; then
    VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
    VALUES="${VALUES},ingress.tls[0].hosts[0]=${INGRESS_HOST}"
    VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"
fi

echo "*** Generating kube yaml from helm template into ${ARTIFACTORY_OUTPUT_YAML}"
helm template "${ARTIFACTORY_CHART}" \
    --namespace "${NAMESPACE}" \
    --name "artifactory" \
    --set "${VALUES}" \
    --set "ingress.hosts.0=${INGRESS_HOST}" \
    --set "serviceAccount.create=false" \
    --set "serviceAccount.name=artifactory" \
    --set "artifactory.uid=0" \
    --values "${VALUES_FILE}" > "${ARTIFACTORY_OUTPUT_YAML}"

if [[ -n "${TLS_SECRET_NAME}" ]]; then
    URL="https://${INGRESS_HOST}"
else
    URL="http://${INGRESS_HOST}"
fi

echo "*** Generating artifactory-access yaml from helm template into ${SECRET_OUTPUT_YAML}"
helm template "${SECRET_CHART}" \
    --namespace "${NAMESPACE}" \
    --set url="http://${INGRESS_HOST}" > "${SECRET_OUTPUT_YAML}"

echo "*** Building final kube yaml from kustomize into ${OUTPUT_YAML}"
kustomize build "${ARTIFACTORY_KUSTOMIZE}" > "${OUTPUT_YAML}"

echo "*** Applying kube yaml ${ARTIFACTORY_OUTPUT_YAML}"
kubectl apply -n "${NAMESPACE}" -f "${OUTPUT_YAML}"

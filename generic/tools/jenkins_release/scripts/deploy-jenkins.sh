#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

NAMESPACE="$1"
JENKINS_HOST="$2"
HELM_VERSION="$3"
TLS_SECRET_NAME="$4"

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi
if [[ -z "${CHART_REPO}" ]]; then
    CHART_REPO="https://kubernetes-charts.storage.googleapis.com/"
fi

NAME="jenkins"

VALUES_FILE="${MODULE_DIR}/jenkins-values.yaml"
JENKINS_CONFIG_CHART="${MODULE_DIR}/charts/jenkins-config"
CLUSTER_ROLE_CHART="${MODULE_DIR}/charts/jenkins-cluster-role"
KUSTOMIZE_TEMPLATE="${MODULE_DIR}/kustomize/jenkins"

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"

JENKINS_KUSTOMIZE="${KUSTOMIZE_DIR}/jenkins"
JENKINS_BASE_KUSTOMIZE="${JENKINS_KUSTOMIZE}/base.yaml"
JENKINS_CONFIG_KUSTOMIZE="${JENKINS_KUSTOMIZE}/jenkins-config.yaml"
CLUSTER_ROLE_KUSTOMIZE="${JENKINS_KUSTOMIZE}/cluster-role.yaml"

JENKINS_YAML="${TMP_DIR}/jenkins.yaml"

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Updating namespace in kustomization.yaml"
sed -i -e "s/tools/${NAMESPACE}/g"  ${KUSTOMIZE_DIR}/jenkins/kustomization.yaml

JENKINS_TLS="false"
JENKINS_URL="http://${JENKINS_HOST}"
HELM_VALUES="master.ingress.hostName=${JENKINS_HOST},master.testEnabled=false"

if [[ -n "${TLS_SECRET_NAME}" ]]; then
    JENKINS_TLS="true"
    JENKINS_URL="https://${JENKINS_HOST}"
    HELM_VALUES="${HELM_VALUES},master.ingress.tls[0].secretName=${TLS_SECRET_NAME}"
    HELM_VALUES="${HELM_VALUES},master.ingress.tls[0].hosts[0]=${JENKINS_HOST}"
    HELM_VALUES="${HELM_VALUES},master.ingress.annotations.ingress\.bluemix\.net/redirect-to-https=True"
fi

if [[ -n "${STORAGE_CLASS}" ]]; then
    HELM_VALUES="${HELM_VALUES},persistence.storageClass=${STORAGE_CLASS}"
fi

echo "*** Generating jenkins yaml from helm template"
helm3 template "${NAME}" jenkins \
    --repo https://kubernetes-charts.storage.googleapis.com/ \
    --version "${HELM_VERSION}" \
    --namespace "${NAMESPACE}" \
    --set ${HELM_VALUES} \
    --values "${VALUES_FILE}" > "${JENKINS_BASE_KUSTOMIZE}"

echo "*** Generating jenkins-config yaml from helm template"
helm3 template jenkins-config "${JENKINS_CONFIG_CHART}" \
    --namespace "${NAMESPACE}" \
    --set jenkins.tls="${JENKINS_TLS}" \
    --set jenkins.host="${JENKINS_HOST}" > "${JENKINS_CONFIG_KUSTOMIZE}"

echo "*** Generating jenkins-config yaml from helm template"
helm3 template jenkins-cluster-role "${CLUSTER_ROLE_CHART}" \
    --namespace "${NAMESPACE}" > "${CLUSTER_ROLE_KUSTOMIZE}"

echo "*** Building final kube yaml from kustomize into ${JENKINS_YAML}"
kustomize build "${JENKINS_KUSTOMIZE}" > "${JENKINS_YAML}"

echo "*** Applying Jenkins yaml to kube"
kubectl apply -n "${NAMESPACE}" -f "${JENKINS_YAML}"

echo "*** Waiting for Jenkins"
"${SCRIPT_DIR}/waitForEndpoint.sh" "${JENKINS_URL}/login" 90 15

echo "*** Waiting for jenkins-config job to complete"
kubectl -n "${NAMESPACE}" wait --for=condition=complete --timeout=10m "job/jenkins-config"
kubectl -n "${NAMESPACE}" wait --for=condition=complete --timeout=0 "job/jenkins-config"

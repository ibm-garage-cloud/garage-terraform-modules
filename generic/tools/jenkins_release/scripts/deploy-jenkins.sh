#!/usr/bin/env bash

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

JENKINS_CHART="${CHART_DIR}/jenkins"

JENKINS_KUSTOMIZE="${KUSTOMIZE_DIR}/jenkins"
JENKINS_BASE_KUSTOMIZE="${JENKINS_KUSTOMIZE}/base.yaml"
JENKINS_CONFIG_KUSTOMIZE="${JENKINS_KUSTOMIZE}/jenkins-config.yaml"
CLUSTER_ROLE_KUSTOMIZE="${JENKINS_KUSTOMIZE}/cluster-role.yaml"

JENKINS_YAML="${TMP_DIR}/jenkins.yaml"

echo "*** Fetching Jenkins helm chart from ${CHART_REPO} into ${CHART_DIR}"
mkdir -p "${CHART_DIR}"
helm fetch --repo "${CHART_REPO}" --untar --untardir "${CHART_DIR}" --version ${HELM_VERSION} jenkins

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Updating namespace in kustomization.yaml"
sed -i -e "s/tools/${NAMESPACE}/g"  ${KUSTOMIZE_DIR}/jenkins/kustomization.yaml

echo "*** Cleaning up helm chart tests"
rm -rf "${JENKINS_CHART}/templates/tests"

JENKINS_TLS="false"
JENKINS_URL="http://${JENKINS_HOST}"
HELM_VALUES="master.ingress.hostName=${JENKINS_HOST}"

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
helm init --client-only
helm template "${JENKINS_CHART}" \
    --namespace "${NAMESPACE}" \
    --name "${NAME}" \
    --set ${HELM_VALUES} \
    --values "${VALUES_FILE}" > "${JENKINS_BASE_KUSTOMIZE}"
if [[ $? -ne - ]]; then
  exit 1
fi

echo "*** Generating jenkins-config yaml from helm template"
helm template "${JENKINS_CONFIG_CHART}" \
    --name jenkins-config \
    --namespace "${NAMESPACE}" \
    --set jenkins.tls="${JENKINS_TLS}" \
    --set jenkins.host="${JENKINS_HOST}" > "${JENKINS_CONFIG_KUSTOMIZE}"

echo "*** Generating jenkins-config yaml from helm template"
helm template "${CLUSTER_ROLE_CHART}" \
    --name jenkins-cluster-role \
    --namespace "${NAMESPACE}" > "${CLUSTER_ROLE_KUSTOMIZE}"

echo "*** Building final kube yaml from kustomize into ${JENKINS_YAML}"
kustomize build "${JENKINS_KUSTOMIZE}" > "${JENKINS_YAML}"
if [[ $? -ne 0 ]]; then
  exit 1
fi

echo "*** Applying Jenkins yaml to kube"
kubectl apply -n "${NAMESPACE}" -f "${JENKINS_YAML}"

echo "*** Waiting for Jenkins"
"${SCRIPT_DIR}/waitForEndpoint.sh" "${JENKINS_URL}/login" 300 6

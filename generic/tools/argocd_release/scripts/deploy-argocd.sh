#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd "${SCRIPT_DIR}/.."; pwd -P)

CHART_NAME="$1"
NAMESPACE="$2"
VERSION="$3"
INGRESS_HOST="$4"
INGRESS_SUBDOMAIN="$5"
ENABLE_ARGO_CACHE="$6"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi

KUSTOMIZE_TEMPLATE="${MODULE_DIR}/kustomize/argocd"
KUSTOMIZE_PATCH_TEMPLATE="${KUSTOMIZE_TEMPLATE}/patch-ingress.yaml"

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"
KUSTOMIZE_PATCH="${KUSTOMIZE_DIR}/argocd/patch-ingress.yaml"

ARGOCD_CHART="${CHART_DIR}/${CHART_NAME}"
SOLSACM_CHART="${MODULE_DIR}/charts/solsa-cm"

ARGOCD_KUSTOMIZE="${KUSTOMIZE_DIR}/argocd"
ARGOCD_BASE_KUSTOMIZE="${ARGOCD_KUSTOMIZE}/base.yaml"
ARGOCD_SOLSACM_KUSTOMIZE="${ARGOCD_KUSTOMIZE}/solsa/solsa-cm.yaml"

ARGOCD_YAML="${TMP_DIR}/argocd.yaml"

HELM_REPO="https://ibm-garage-cloud.github.io/argo-helm/"

echo "*** Fetching the helm chart from ${HELM_REPO}"
mkdir -p ${CHART_DIR}
helm init --client-only
helm fetch --repo ${HELM_REPO} \
    --untar \
    --untardir ${CHART_DIR} \
    --version ${VERSION} \
    ${CHART_NAME}

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

HELM_VALUES="redis.enabled=${ENABLE_ARGO_CACHE}"
if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  HELM_VALUES="${HELM_VALUES},server.ingress.enabled=true,server.ingress.hosts.0=${INGRESS_HOST}"
  URL="http://${INGRESS_HOST}"

  if [[ -n "${TLS_SECRET_NAME}" ]]; then
    HELM_VALUES="${HELM_VALUES},server.ingress.tls.0.secretName=${TLS_SECRET_NAME},server.ingress.tls.0.hosts.0=${INGRESS_HOST}"
    URL="https://${INGRESS_HOST}"
  fi
fi

echo "*** Generating kube yaml from helm template into ${ARGOCD_BASE_KUSTOMIZE}"
helm template "${ARGOCD_CHART}" \
    --namespace "${NAMESPACE}" \
    --name "argocd" \
    --set "${HELM_VALUES}" > ${ARGOCD_BASE_KUSTOMIZE}

echo "*** Generating solsa-cm yaml from helm template into ${ARGOCD_SOLSACM_KUSTOMIZE}"
helm template ${SOLSACM_CHART} \
    --namespace ${NAMESPACE} \
    --set ingress.subdomain="${INGRESS_SUBDOMAIN}" \
    --set ingress.tlssecret="${TLS_SECRET_NAME}" > ${ARGOCD_SOLSACM_KUSTOMIZE}

echo "*** Building final kube yaml from kustomize into ${ARGOCD_YAML}"
kustomize build "${ARGOCD_KUSTOMIZE}" > "${ARGOCD_YAML}"

echo "*** Applying kube yaml ${ARGOCD_YAML}"
kubectl apply -n "${NAMESPACE}" -f "${ARGOCD_YAML}"


if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5

  oc project ${NAMESPACE}
  oc create route edge argocd --service=argocd-server --port=https --insecure-policy=Redirect

  HOST=$(oc get route argocd -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  URL="https://${HOST}"
fi

sleep 5
PASSWORD=$(kubectl get pods -n tools -l app.kubernetes.io/name=argocd-server -o jsonpath='{.items[0].metadata.name}')

npm i -g @garage-catalyst/ibm-garage-cloud-cli
igc tool-config --name argocd --url "${URL}" --username admin --password "${PASSWORD}"

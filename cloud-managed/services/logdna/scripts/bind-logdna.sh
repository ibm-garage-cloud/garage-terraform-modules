#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

CLUSTER_TYPE="$1"
LOGDNA_AGENT_KEY="$2"
REGION="$3"
NAMESPACE="$4"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
   export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
   TMP_DIR="${MODULE_DIR}/.tmp"
fi

mkdir -p ${TMP_DIR}
YAML_FILE=${TMP_DIR}/logdna-agent-key.yaml

echo "*** Cleaning up existing namespace: ${NAMESPACE}"
kubectl delete namespace "${NAMESPACE}"

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
    kubectl create namespace "${NAMESPACE}"

    LOGDNA_AGENT_DS_YAML="https://assets.us-south.logging.cloud.ibm.com/clients/logdna-agent-ds.yaml"
else
    oc adm new-project "${NAMESPACE}"
    oc project "${NAMESPACE}"
    oc create serviceaccount logdna-agent
    oc adm policy add-scc-to-user privileged -n "${NAMESPACE}" -z logdna-agent

    KUSTOMIZE_TEMPLATE="${MODULE_DIR}/kustomize"
    LOGDNA_PATCH_TEMPLATE="${KUSTOMIZE_TEMPLATE}/logdna-os/patch-daemonset.yaml"

    KUSTOMIZE_DIR="${TMP_DIR}/kustomize"
    LOGDNA_KUSTOMIZE="${KUSTOMIZE_DIR}/logdna-os"
    LOGDNA_BASE_YAML="${LOGDNA_KUSTOMIZE}/base.yaml"
    LOGDNA_PATCH_YAML="${LOGDNA_KUSTOMIZE}/patch-daemonset.yaml"

    mkdir -pv "${KUSTOMIZE_DIR}"
    echo "*** Copying ${KUSTOMIZE_TEMPLATE}/* to ${KUSTOMIZE_DIR}"
    cp -Rv "${KUSTOMIZE_TEMPLATE}"/* "${KUSTOMIZE_DIR}"

    curl https://raw.githubusercontent.com/logdna/logdna-agent/master/logdna-agent-ds-os.yaml -o "${LOGDNA_BASE_YAML}"

    LOGDNA_API_HOST="api.${REGION}.logging.cloud.ibm.com"
    LOGDNA_LOG_HOST="logs.${REGION}.logging.cloud.ibm.com"

    cat "${LOGDNA_PATCH_TEMPLATE}" | \
      sed "s/LDAPIHOST_VALUE/${LOGDNA_API_HOST}/g" | \
      sed "s/LDLOGHOST_VALUE/${LOGDNA_LOG_HOST}/g" > ${LOGDNA_PATCH_YAML}

    LOGDNA_AGENT_DS_YAML="${TMP_DIR}/logdna-agent-ds-os.yaml"

    kustomize build "${LOGDNA_KUSTOMIZE}" > "${LOGDNA_AGENT_DS_YAML}"
fi

echo "*** Creating logdna-agent-key secret in ${NAMESPACE}"
kubectl create secret generic logdna-agent-key -n "${NAMESPACE}" --from-literal=logdna-agent-key="${LOGDNA_AGENT_KEY}"

echo "*** Creating logdna-agent daemon set in ${NAMESPACE}"
kubectl apply -n "${NAMESPACE}" -f "${LOGDNA_AGENT_DS_YAML}"

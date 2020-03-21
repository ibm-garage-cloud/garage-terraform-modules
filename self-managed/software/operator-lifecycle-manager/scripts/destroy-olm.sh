#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)

if [[ -n "${KUBECONFIG_IKS}" ]]; then
  export KUBECONFIG="${KUBECONFIG_IKS}"
fi

echo "CLUSTER_TYPE: ${CLUSTER_TYPE}"
if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  echo "Cluster version already had OLM: ${CLUSTER_VERSION}"
  exit 0
fi

kubectl delete deployment -n olm --all
"${SCRIPT_DIR}/kill-kube-ns"
kubectl delete namespace olm
exit 0

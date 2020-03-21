#!/usr/bin/env bash

if [[ -n "${KUBECONFIG_IKS}" ]]; then
  export KUBECONFIG="${KUBECONFIG_IKS}"
fi

echo "CLUSTER_TYPE: ${CLUSTER_TYPE}"
if [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  echo "Cluster version already had OLM: ${CLUSTER_VERSION}"
  exit 0
fi

kubectl delete deployment -n olm --all
kubectl delete namespace olm

#!/usr/bin/env bash

NAMESPACE="$1"

if [[ -z "${NAMESPACE}" ]]; then
    echo "Namespace is required as the first parameter"
    exit 1
fi

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl get namespaces "${NAMESPACE}" 1> /dev/null 2> /dev/null && \
  kubectl delete namespace "${NAMESPACE}" --wait
exit 0

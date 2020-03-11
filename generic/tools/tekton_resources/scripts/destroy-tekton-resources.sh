#!/usr/bin/env bash

NAMESPACE="$1"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete tasks --all -n "${NAMESPACE}" || true
kubectl delete pipelines --all -n "${NAMESPACE}" || true

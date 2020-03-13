#!/usr/bin/env bash

NAMESPACE="$1"
LABEL="$2"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete deployment,ingress,role,rolebinding,route,service,serviceaccount,configmap,secret -n "${NAMESPACE}" -l app="${LABEL}"

#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

if [[ -z "${NAME}" ]]; then
  NAME="argocd"
fi

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete deployment,service,configmap,secret,ingress,route -n "${NAMESPACE}" -l app="${NAME}"

#!/usr/bin/env bash

NAMESPACE="$1"
NAME="$2"

if [[ -z "${NAME}" ]]; then
  NAME="argocd"
fi

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete deployment,service,configmap,secret,ingress -n "${NAMESPACE}" -l app="${NAME}"

if kubectl get route -n "${NAMESPACE}" -l app="${LABEL}"; then
  kubectl delete route -n "${NAMESPACE}" -l app="${LABEL}"
fi
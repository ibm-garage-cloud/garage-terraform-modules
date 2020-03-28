#!/usr/bin/env bash

NAMESPACE="$1"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete secret,deployment,ingress,service -n "${NAMESPACE}" -l app=pact-broker

if kubectl get route -n "${NAMESPACE}" -l app="${LABEL}"; then
  kubectl delete route -n "${NAMESPACE}" -l app="${LABEL}"
fi

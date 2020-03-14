#!/usr/bin/env bash

NAMESPACE="$1"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

kubectl delete secret,deployment,ingress,route,service -n "${NAMESPACE}" -l app=pact-broker

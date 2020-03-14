#!/usr/bin/env bash

NAMESPACE="$1"
APP_NAME="$2"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

echo "Destroying postgres db"
kubectl delete deploymentconfig,service,secret,pvc -l "app=${APP_NAME}" -n "${NAMESPACE}"

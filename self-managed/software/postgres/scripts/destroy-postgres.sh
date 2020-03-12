#!/usr/bin/env bash

NAMESPACE="$1"
APP_NAME="$2"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

echo "Destroying sonarqube resources"
kubectl delete all -l "app=${APP_NAME}" -n "${NAMESPACE}" || true
kubectl delete secret -l "app=${APP_NAME}" -n "${NAMESPACE}" || true
kubectl delete pvc -l "app=${APP_NAME}" -n "${NAMESPACE}" || true

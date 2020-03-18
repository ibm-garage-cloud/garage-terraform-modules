#!/usr/bin/env bash

NAMESPACE="$1"
APP_NAME="$2"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
  export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${APP_NAME}" ]]; then
  APP_NAME=sonarqube
fi

kubectl delete all,deployment,statefulset,secret,configmap,service,ingress,pvc -n "${NAMESPACE}" -l "app=${APP_NAME}"

echo "Destroying postgres db"
kubectl delete all,deploymentconfig,service,secret,pvc -l "app=${APP_NAME}" -n "${NAMESPACE}"

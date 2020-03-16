#!/usr/bin/env bash

RELEASE_NAME="$1"
NAMESPACE="$2"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

helm3 uninstall "${RELEASE_NAME}" --namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null
kubectl delete configmap/ibmcloud-config -namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null
kubectl delete secret/ibmcloud-apikey --namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null

exit 0

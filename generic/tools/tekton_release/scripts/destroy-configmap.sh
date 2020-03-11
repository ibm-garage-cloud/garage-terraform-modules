#!/usr/bin/env bash

print_usage() {
    echo "Missing required arguments"
    echo "Usage: $0 {CONFIGMAP_NAME} {TO_NAMESPACE} [{FROM_NAMESPACE}]"
}

if [[ -z "$1" ]]; then
    print_usage
    exit 1
else
   CONFIGMAP_NAME="$1"
fi

if [[ -z "$2" ]]; then
    print_usage
    exit 1
else
   TO_NAMESPACE="$2"
fi

kubectl delete configmap ${CONFIGMAP_NAME} --namespace=${TO_NAMESPACE}
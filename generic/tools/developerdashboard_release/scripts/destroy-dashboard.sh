#!/usr/bin/env bash

NAMESPACE="$1"
CLUSTER_TYPE="$2"

kubectl delete -n "${NAMESPACE}" serviceaccount,role,rolebinding,service,deployment,ingress -l app=developer-dashboard
kubectl delete -n "${NAMESPACE}" configmap,secret -l app=dashboard

if [[ "${CLUSTER_TYPE}" != "kubernetes" ]]; then
  kubectl delete -n "${NAMESPACE}" route -l app=developer-dashboard
fi

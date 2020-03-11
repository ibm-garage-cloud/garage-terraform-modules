#!/usr/bin/env bash

NAMESPACE="$1"

# installs the tekton dashboard
# note: The namespace is hardcoded in the dashboard-latest-release file
kubectl delete namespace "${NAMESPACE}"  1> /dev/null 2> /dev/null || true

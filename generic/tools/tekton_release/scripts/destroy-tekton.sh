#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

YAML_FILE=${MODULE_DIR}/tekton.yaml

echo "*** deleting tekton openshift-pipelines-operator"
kubectl delete -f ${YAML_FILE} || true

# TODO: do this delete in a more generic way
oc delete ClusterServiceVersion openshift-pipelines-operator.v0.10.7 -n openshift-operators || true

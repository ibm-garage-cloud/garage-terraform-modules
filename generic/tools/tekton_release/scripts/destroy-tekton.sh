#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

YAML_FILE=${MODULE_DIR}/tekton.yaml

echo "*** deleting tekton openshift-pipelines-operator"
kubectl delete -f ${YAML_FILE} || true


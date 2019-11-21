#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
MODULE_DIR=$(cd ${SCRIPT_DIR}/..; pwd -P)

YAML_FILE=${MODULE_DIR}/tekton.yaml

echo "*** creating tekton openshift-pipelines-operator"
kubectl apply -f ${YAML_FILE}

echo "*** Waiting for Tekton CRDs to be available"
until oc get crd tasks.tekton.dev
do
    echo '>>> waiting for tekton CRD availability'
    sleep 60
done
echo '>>> Tekton CRDs are available'
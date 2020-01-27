#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname $0); pwd -P)
CHART_DIR=$(cd "${SCRIPT_DIR}/../charts"; pwd -P)

NAMESPACE="$1"
VOLUME_CAPACITY="$2"
STORAGE_CLASS="$3"

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR=./tmp
fi

mkdir -p ${TMP_DIR}

YAML_OUTPUT=${TMP_DIR}/jenkins-config.yaml

echo "Creating jenkins-ephemeral instance"
oc new-app jenkins-ephemeral -n "${NAMESPACE}"

JENKINS_HOST=$(oc get route jenkins -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')
JENKINS_URL="https://${JENKINS_HOST}"

if [[ -n "${SERVER_URL}" ]]; then
  PIPELINE_URL="${SERVER_URL}/console/projects"
else
  PIPELINE_URL="${JENKINS_URL}"
fi

helm template "${CHART_DIR}/pipeline-config" \
    --name "pipeline-config" \
    --namespace "${NAMESPACE}" \
    --set "pipeline.url=${PIPELINE_URL}" \
    --set "pipeline.tls=true" > ${YAML_OUTPUT}
kubectl apply --namespace "${NAMESPACE}" -f ${YAML_OUTPUT}

echo "*** Waiting for Jenkins on ${JENKINS_URL}"
until curl --insecure -Isf "${JENKINS_URL}/login"; do
    echo '>>> waiting for Jenkins'
    sleep 300
done
echo '>>> Jenkins has started'

#!/usr/bin/env bash

SERVICE_NAME="$1"
SERVICE_NAMESPACE="$2"
SERVICE_PLAN="$3"
SERVICE_CLASS="$4"
BINDING_NAME="$5"
BINDING_NAMESPACE_JSON="$6"
BINDING_NAMESPACE_MAIN="$7"

SERVICE_NAME=`echo $SERVICE_NAME | tr '[:upper:]' '[:lower:] ' `

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
  TMP_DIR="./.tmp"
fi
mkdir -p ${TMP_DIR}

SERVICE_YAML_FILE="${TMP_DIR}/${SERVICE_NAME}.service.yaml"
BINDING_YAML_FILE="${TMP_DIR}/${SERVICE_NAME}.binding.yaml"

BINDING_NAMESPACES=$(echo "${BINDING_NAMESPACE_JSON}" | sed -E 's/[[](.*)[]]/\1/g' | sed 's/\"//g')
echo "BINDING_NAMESPACES_JSON=${BINDING_NAMESPACE_JSON}"
echo "BINDING_NAMESPACES=${BINDING_NAMESPACES}"

cat > "${SERVICE_YAML_FILE}" << EOL
apiVersion: ibmcloud.ibm.com/v1alpha1
kind: Service
metadata:
  name: ${SERVICE_NAME}
spec:
  plan: ${SERVICE_PLAN}
  serviceClass: ${SERVICE_CLASS}
  context:
    region: ${REGION}
    resourcegroup: ${RESOURCE_GROUP}
EOL

cat > "${BINDING_YAML_FILE}" << EOL
apiVersion: ibmcloud.ibm.com/v1alpha1
kind: Binding
metadata:
  name: ${BINDING_NAME}
spec:
  serviceName: ${SERVICE_NAME}
  serviceNamespace: ${SERVICE_NAMESPACE}
EOL

kubectl apply -f "${SERVICE_YAML_FILE}" -n "${SERVICE_NAMESPACE}"

until [[ $(kubectl get "service.ibmcloud/${SERVICE_NAME}" -n "${SERVICE_NAMESPACE}" -o jsonpath='{.status.state}') =~ Online|Failed ]]; do
  echo ">>> Waiting for ${SERVICE_CLASS} to be ready"
  sleep 300
done

if [[ $(kubectl get "service.ibmcloud/${SERVICE_NAME}" -n "${SERVICE_NAMESPACE}" -o jsonpath='{.status.state}') == "Failed" ]]; then
  echo "*** Service deploy $SERVICE_NAME failed"
  exit 1
else
  echo ">>> ${SERVICE_NAME} is ready"
fi

for namespace in $(echo "${BINDING_NAMESPACES}" | sed "s/,/ /g"); do
  echo "*** Binding service as ${namespace}/${BINDING_NAME}"
  kubectl apply -f "${BINDING_YAML_FILE}" -n "${namespace}"
done

if [[ -n "${BINDING_NAMESPACE_MAIN}" ]]; then
  if [[ ! $(kubectl get binding.ibmcloud/${BINDING_NAME} -n "${BINDING_NAMESPACE_MAIN}") ]]; then
    echo "Service binding ${BINDING_NAMESPACE_MAIN}/${BINDING_NAME} not found"
    exit 1
  fi

  until [[ $(kubectl get "binding.ibmcloud/${BINDING_NAME}" -n "${BINDING_NAMESPACE_MAIN}" -o jsonpath='{.status.state}') =~ Online|Failed ]]; do
    echo ">>> Waiting for ${BINDING_NAMESPACE_MAIN}/${BINDING_NAME} to be ready"
    sleep 300
  done

  if [[ $(kubectl get "binding.ibmcloud/${BINDING_NAME}" -n "${BINDING_NAMESPACE_MAIN}" -o jsonpath='{.status.state}') == "Failed" ]]; then
    echo "*** Binding ${SERVICE_NAMESPACE}/${SERVICE_NAME} to ${BINDING_NAMESPACE_MAIN}/${BINDING_NAME} failed"
    exit 1
  else
    echo ">>> ${BINDING_NAMESPACE_MAIN}/${BINDING_NAME} is ready"
  fi
fi

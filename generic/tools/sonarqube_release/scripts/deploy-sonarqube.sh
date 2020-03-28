#!/usr/bin/env bash

set -e

SCRIPT_DIR=$(cd $(dirname $0); pwd -P);
ROOT_DIR=$(cd "${SCRIPT_DIR}/.."; pwd - P)

NAMESPACE="$1"
SONARQUBE_HOST="$2"
VERSION="$3"
SERVICE_ACCOUNT="$4"
VOLUME_CAPACITY="$5"
PLUGINS="$6"

if [[ -n "${KUBECONFIG_IKS}" ]]; then
    export KUBECONFIG="${KUBECONFIG_IKS}"
fi

if [[ -z "${TMP_DIR}" ]]; then
    TMP_DIR=".tmp"
fi
if [[ -z "${CHART_REPO}" ]]; then
    CHART_REPO="https://oteemo.github.io/charts"
fi

NAME="sonarqube"

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"

KUSTOMIZE_TEMPLATE="${ROOT_DIR}/kustomize/sonarqube"

VALUES_FILE="${ROOT_DIR}/sonarqube-values.yaml"

SONARQUBE_KUSTOMIZE="${KUSTOMIZE_DIR}/sonarqube"
SONARQUBE_BASE_KUSTOMIZE="${SONARQUBE_KUSTOMIZE}/base.yaml"
PATCH_DEPLOYMENT_KUSTOMIZE="${SONARQUBE_KUSTOMIZE}/patch-deployment.yaml"

PATCH_DEPLOYMENT_TEMPLATE="${KUSTOMIZE_TEMPLATE}/patch-deployment.yaml"

SONARQUBE_YAML="${TMP_DIR}/sonarqube.yaml"
SECRET_OUTPUT_YAML="${TMP_DIR}/sonarqube-secret.yaml"

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Updating patch-deployment.yaml with service account"
cat "${PATCH_DEPLOYMENT_TEMPLATE}" | sed "s/%SERVICE_ACCOUNT_NAME%/${SERVICE_ACCOUNT}/g" > ${PATCH_DEPLOYMENT_KUSTOMIZE}

PLUGIN_YAML=$(echo $PLUGINS | sed -E "s/[[](.*)[]]/{\1}/g")

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  VALUES=ingress.hosts[0].name="${SONARQUBE_HOST}"
  if [[ -n "${TLS_SECRET_NAME}" ]]; then
      VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
      VALUES="${VALUES},ingress.tls[0].hosts[0]=${SONARQUBE_HOST}"
  fi
else
  VALUES="ingress.enabled=false"
fi

if [[ -n "${STORAGE_CLASS}" ]]; then
  VALUES="${VALUES},persistence.storageClass=${STORAGE_CLASS}"
fi

if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  DATABASE_HOST="postgresql"
  DATABASE_PORT="5432"
  DATABASE_USERNAME="sonarUser"
  DATABASE_PASSWORD="sonarPass"
  DATABASE_NAME="sonarqube"

  echo "*** Deplopying postgresql-persistent deployment config"
  oc new-app postgresql-persistent -n "${NAMESPACE}" \
    --name="${DATABASE_NAME}" \
    -l tools=sonarqube \
    -p POSTGRESQL_USER="${DATABASE_USERNAME}" \
    -p POSTGRESQL_PASSWORD="${DATABASE_PASSWORD}" \
    -p POSTGRESQL_DATABASE="${DATABASE_NAME}" \
    -p VOLUME_CAPACITY="${VOLUME_CAPACITY}"
fi

if [[ -n "${DATABASE_HOST}" ]] && \
 [[ -n "${DATABASE_PORT}" ]] && \
 [[ -n "${DATABASE_NAME}" ]] && \
 [[ -n "${DATABASE_USERNAME}" ]] && \
 [[ -n "${DATABASE_PASSWORD}" ]]; then

  echo "*** Database information provided for ${DATABASE_HOST}:${DATABASE_PORT}/${DATABASE_NAME}"
  VALUES="${VALUES},postgresql.enabled=false,postgresql.postgresqlServer=${DATABASE_HOST},postgresql.postgresqlDatabase=${DATABASE_NAME},postgresql.postgresqlUsername=${DATABASE_USERNAME},postgresql.postgresqlPassword=${DATABASE_PASSWORD},postgresql.service.port=${DATABASE_PORT}"
fi

echo "*** Generating sonarqube yaml from helm template with plugins ${PLUGIN_YAML}"
helm3 template "${NAME}" sonarqube \
    --namespace "${NAMESPACE}" \
    --repo "${CHART_REPO}" \
    --version "${VERSION}" \
    --set ${VALUES} \
    --set postgresql.persistence.enabled=false \
    --set postgresql.volumePermissions.enabled=false \
    --set postgresql.persistence.storageClass="${STORAGE_CLASS}" \
    --set plugins.install=${PLUGIN_YAML} \
    --values "${VALUES_FILE}" > "${SONARQUBE_BASE_KUSTOMIZE}"

if [[ -n "${TLS_SECRET_NAME}" ]]; then
    SONARQUBE_URL="https://${SONARQUBE_HOST}"
else
    SONARQUBE_URL="http://${SONARQUBE_HOST}"
fi

echo "*** Building final kube yaml from kustomize into ${SONARQUBE_YAML}"
kustomize build "${SONARQUBE_KUSTOMIZE}" > "${SONARQUBE_YAML}"

echo "*** Applying Sonarqube yaml to kube"
kubectl apply -n "${NAMESPACE}" -f "${SONARQUBE_YAML}"

if [[ "${CLUSTER_TYPE}" == "openshift" ]] || [[ "${CLUSTER_TYPE}" == "ocp3" ]] || [[ "${CLUSTER_TYPE}" == "ocp4" ]]; then
  sleep 5

  oc project ${NAMESPACE}
  oc create route edge sonarqube --service=sonarqube-sonarqube --insecure-policy=Redirect

  HOST=$(oc get route sonarqube -n "${NAMESPACE}" -o jsonpath='{ .spec.host }')

  SONARQUBE_URL="https://${HOST}"
fi

helm3 repo add toolkit-charts https://ibm-garage-cloud.github.io/toolkit-charts/
helm3 template sonarqube toolkit-charts/tool-config \
  --namespace "${NAMESPACE}" \
  --set url="${SONARQUBE_URL}" \
  --set username=admin \
  --set password=admin > "${SECRET_OUTPUT_YAML}"

kubectl apply -n "${NAMESPACE}" -f "${SECRET_OUTPUT_YAML}"

echo "*** Waiting for Sonarqube"
${SCRIPT_DIR}/waitForEndpoint.sh "${SONARQUBE_URL}/about" 120 10

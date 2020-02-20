#!/usr/bin/env bash

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
    CHART_REPO="https://kubernetes-charts.storage.googleapis.com/"
fi

NAME="sonarqube"

CHART_DIR="${TMP_DIR}/charts"
KUSTOMIZE_DIR="${TMP_DIR}/kustomize"

SONARQUBE_CHART="${CHART_DIR}/sonarqube"

KUSTOMIZE_TEMPLATE="${ROOT_DIR}/kustomize/sonarqube"

VALUES_FILE="${ROOT_DIR}/sonarqube-values.yaml"

SONARQUBE_KUSTOMIZE="${KUSTOMIZE_DIR}/sonarqube"
SONARQUBE_BASE_KUSTOMIZE="${SONARQUBE_KUSTOMIZE}/base.yaml"
PATCH_DEPLOYMENT_KUSTOMIZE="${SONARQUBE_KUSTOMIZE}/patch-deployment.yaml"

PATCH_DEPLOYMENT_TEMPLATE="${KUSTOMIZE_TEMPLATE}/patch-deployment.yaml"

SONARQUBE_YAML="${TMP_DIR}/sonarqube.yaml"

echo "*** Fetching Sonarqube helm chart from ${CHART_REPO} into ${CHART_DIR}"
mkdir -p "${CHART_DIR}"
helm fetch --repo "${CHART_REPO}" --untar --untardir "${CHART_DIR}" --version "${VERSION}" sonarqube

echo "*** Setting up kustomize directory"
mkdir -p "${KUSTOMIZE_DIR}"
cp -R "${KUSTOMIZE_TEMPLATE}" "${KUSTOMIZE_DIR}"

echo "*** Updating patch-deployment.yaml with service account"
cat "${PATCH_DEPLOYMENT_TEMPLATE}" | sed "s/%SERVICE_ACCOUNT_NAME%/${SERVICE_ACCOUNT}/g" > ${PATCH_DEPLOYMENT_KUSTOMIZE}

echo "*** Cleaning up helm chart tests"
rm "${SONARQUBE_CHART}/templates/sonarqube-test.yaml"
rm "${SONARQUBE_CHART}/templates/test-config.yaml"

PLUGIN_YAML=$(echo $PLUGINS | sed -E "s/[[](.*)[]]/{\1}/g")

if [[ "${CLUSTER_TYPE}" == "kubernetes" ]]; then
  VALUES=ingress.hosts.0.name="${SONARQUBE_HOST}"
  if [[ -n "${TLS_SECRET_NAME}" ]]; then
      VALUES="${VALUES},ingress.tls[0].secretName=${TLS_SECRET_NAME}"
      VALUES="${VALUES},ingress.tls[0].hosts[0]=${SONARQUBE_HOST}"
      VALUES="${VALUES},ingress.annotations.ingress\.bluemix\.net/redirect-to-https='True'"
  fi
else
  VALUES="ingress.enabled=false"
fi

if [[ -n "${STORAGE_CLASS}" ]]; then
  VALUES="${VALUES},persistence.storageClass=${STORAGE_CLASS}"
fi

echo "*** Generating sonarqube yaml from helm template with plugins ${PLUGIN_YAML}"
helm init --client-only
helm template "${SONARQUBE_CHART}" \
    --namespace "${NAMESPACE}" \
    --name "${NAME}" \
    --set ${VALUES} \
    --set persistence.size="${VOLUME_CAPACITY}" \
    --set postgresql.postgresServer="${DATABASE_HOST}" \
    --set postgresql.service.port="${DATABASE_PORT}" \
    --set postgresql.postgresDatabase="${DATABASE_NAME}" \
    --set postgresql.postgresUser="${DATABASE_USERNAME}" \
    --set postgresql.postgresPassword="${DATABASE_PASSWORD}" \
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

if [[ ! $(command -v igc) ]]; then
  npm i -g @ibmgaragecloud/cloud-native-toolkit-cli
fi
igc tool-config --name sonarqube --url "${SONARQUBE_URL}" --username admin --password admin

echo "*** Waiting for Sonarqube"
until ${SCRIPT_DIR}/checkPodRunning.sh sonarqube-sonarqube; do
    echo '>>> waiting for Sonarqube'
    sleep 300
done
echo '>>> Sonarqube has started'

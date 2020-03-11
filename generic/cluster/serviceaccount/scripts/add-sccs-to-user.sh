#!/usr/bin/env bash

SCC_LIST_DELIM=$(echo "${1}" | sed -E 's/[[](.*)[]]/\1/g' | sed 's/\"//g')

oc get serviceaccount "${SERVICE_ACCOUNT_NAME}" -n "${NAMESPACE}"

IFS=',' read -ra SCC_LIST <<< "$SCC_LIST_DELIM"
for scc in "${SCC_LIST[@]}"; do
  oc adm policy add-scc-to-user "${scc}" -n "${NAMESPACE}" -z "${SERVICE_ACCOUNT_NAME}"
done
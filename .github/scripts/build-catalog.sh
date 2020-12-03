#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
BASE_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd -P)

DEST_DIR="$1"

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="${BASE_DIR}/dist"
fi

rm -rf "${DEST_DIR}"
mkdir -p "${DEST_DIR}"

yq r -j "${BASE_DIR}/catalog.yaml" | jq -r '.[] | .category' | while read category; do
  echo "*** category: ${category}"

  SELECTION=$(yq r -j "${BASE_DIR}/catalog.yaml" | jq -r --arg CATEGORY "${category}" '.[] | select(.category == $CATEGORY).selection' | grep -v "null")
  if [[ -z "${SELECTION}" ]]; then
    SELECTION="multiple"
  fi

  echo "category: ${category}" > "${DEST_DIR}/${category}.yaml"
  echo "selection: ${SELECTION}" >> "${DEST_DIR}/${category}.yaml"
  echo "modules:" >> "${DEST_DIR}/${category}.yaml"
  yq r -j "${BASE_DIR}/catalog.yaml" | jq -r --arg CATEGORY "${category}" '.[] | select(.category == $CATEGORY).modules | .[]' | while read module_url; do
    echo "module_url: ${module_url}"
    curl -sL "${module_url}" | yq p - "[+]" >> "${DEST_DIR}/${category}.yaml"
  done
done

rm -f "${DEST_DIR}/index.yaml"

ls "${DEST_DIR}"/*.yaml | while read category_file; do
  touch "${DEST_DIR}/index.yaml"

  yq p "${category_file}" '[0]' | yq p - categories | yq m -i -a "${DEST_DIR}/index.yaml" -
  rm "${category_file}"
done

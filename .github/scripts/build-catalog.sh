#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
BASE_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd -P)

DEST_DIR="$1"

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="${BASE_DIR}/dist"
fi

rm -rf "${DEST_DIR}"
mkdir -p "${DEST_DIR}"

yq r -j "${BASE_DIR}/catalog.yaml" | jq -r '.categories | .[] | .category' | while read category; do
  echo "*** category: ${category}"

  yq r -j "${BASE_DIR}/catalog.yaml" | \
    jq -r --arg CATEGORY "${category}" '.categories | .[] | select(.category == $CATEGORY) | del(.modules)' | \
    yq r --prettyPrint - > "${DEST_DIR}/${category}.yaml"

  yq r -j "${BASE_DIR}/catalog.yaml" | \
    jq -r '.categories | .[] | select(.category == "cluster") | .modules | .[]' | \
    while read module_url; do

    echo "module_url: ${module_url}"
    curl -sL "${module_url}" | \
      yq p - "[+]" | yq p - "modules" | yq m -i -a "${DEST_DIR}/${category}.yaml" -
  done
done

rm -f "${DEST_DIR}/index.yaml"

echo "Touching ${DEST_DIR}/index.yaml"
echo "" > "${DEST_DIR}/index.yaml"

echo "Merging categories"

ls "${DEST_DIR}"/*.yaml | grep -v index.yaml | while read category_file; do
  yq p "${category_file}" "[+]" | yq p - "categories" | yq m -i -a "${DEST_DIR}/index.yaml" -
  rm "${category_file}"
done

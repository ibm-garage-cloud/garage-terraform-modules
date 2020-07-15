#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd -P)
BASE_DIR=$(cd "${SCRIPT_DIR}/../.." && pwd -P)

DEST_DIR="$1"

if [[ -z "${DEST_DIR}" ]]; then
  DEST_DIR="${BASE_DIR}/dist"
fi

rm -rf "${DEST_DIR}"
mkdir -p "${DEST_DIR}"

cat "${BASE_DIR}/catalog.yaml" | grep -E "^[^ ]+:$" | sed "s/://g" | while read category; do
  echo "*** category: ${category}"
  yq r "${BASE_DIR}/catalog.yaml" "${category}" | sed -E "s/^ *- *//g" | while read module_url; do
    echo "module_url: ${module_url}"
    curl -sL "${module_url}" | yq p - "[+]" >> "${DEST_DIR}/${category}.yaml"
  done
done

rm -f "${DEST_DIR}/index.yaml"

ls "${DEST_DIR}"/*.yaml | while read category_file; do
  category=$(basename "${category_file}" | sed -E "s/(.*).yaml/\1/g")

  yq p "${category_file}" "${category}" >> "${DEST_DIR}/index.yaml"
  rm "${category_file}"
done

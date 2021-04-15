#!/bin/bash
#
# Copyright (c) 2018-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)

DEFAULT_REGISTRY="quay.io"
DEFAULT_ORGANIZATION="prabhav"
DEFAULT_TAG="nightly"

REGISTRY=${REGISTRY:-${DEFAULT_REGISTRY}}
ORGANIZATION=${ORGANIZATION:-${DEFAULT_ORGANIZATION}}
TAG=${TAG:-${DEFAULT_TAG}}

NAME_FORMAT="${REGISTRY}/${ORGANIZATION}"

PUSH_IMAGES=false
if [ "$1" == "--push" ] || [ "$2" == "--push" ]; then
  PUSH_IMAGES=true
fi

RM_IMAGES=false
if [ "$1" == "--rm" ] || [ "$2" == "--rm" ]; then
  RM_IMAGES=true
fi

BUILT_IMAGES=""
while read -r line; do
  dev_container_name=$(echo "$line" | tr -s ' ' | cut -f 1 -d ' ')
  base_image_name=$(echo "$line" | tr -s ' ' | cut -f 2 -d ' ')
  base_image_digest=$(echo "$line" | tr -s ' ' | cut -f 3 -d ' ')
  platforms_supported=$(echo "$line" | tr -s ' ' | cut -f 4 -d ' ')
  echo "Building ${NAME_FORMAT}/${dev_container_name}:${TAG} based on $base_image_name ..."
  if ${PUSH_IMAGES}; then
    docker buildx build --platform ${platforms_supported} -t "${NAME_FORMAT}/${dev_container_name}:${TAG}" --no-cache --push --build-arg FROM_IMAGE="$base_image_digest" "${SCRIPT_DIR}"/ | cat
  else 
    docker buildx build --platform ${platforms_supported} -t "${NAME_FORMAT}/${dev_container_name}:${TAG}" --no-cache --build-arg FROM_IMAGE="$base_image_digest" "${SCRIPT_DIR}"/ | cat
  fi
  #if ${PUSH_IMAGES}; then
    #echo "Pushing ${NAME_FORMAT}/${dev_container_name}:${TAG} to remote registry"
    #docker push "${NAME_FORMAT}/${dev_container_name}:${TAG}" | cat
  #fi
  #if ${RM_IMAGES}; then # save disk space by deleting the image we just published
    #echo "Deleting ${NAME_FORMAT}/${dev_container_name}:${TAG} from local registry"
    #docker rmi "${NAME_FORMAT}/${dev_container_name}:${TAG}"
  #fi
  BUILT_IMAGES="${BUILT_IMAGES}    ${NAME_FORMAT}/${dev_container_name}:${TAG}\n"
done < "${SCRIPT_DIR}"/base_images

echo "Built images:"
echo -e "$BUILT_IMAGES"

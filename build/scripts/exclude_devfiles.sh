#!/bin/bash
#
# Copyright (c) 2020-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

SCRIPT_DIR=$(cd "$(dirname "$0")" || exit; pwd)
#LOG_FILE="/tmp/image_digests.log"
ARCH=$1
pip install yq

function handle_error() {
  the_image="$1"
  echo "  Could not read image metadata through skopeo inspect; skip $the_image"
  echo -n "  Reason: "
  sed 's|^|    |g' $LOG_FILE
}

supported=false

for dir in devfiles/*/     # list directories in the form "/tmp/dirname/"
do
    dir=${dir%*/}      # remove the trailing "/"
    for image in $(yq -r '.components[]?.image' "$dir/devfile.yaml" | grep -v "null" | sort | uniq); do
        if [[ $(skopeo inspect docker://"${image}" --raw | grep manifests) ]]; then
            base_image_platforms_list=$(skopeo inspect docker://"${image}" --raw | jq -r '.manifests[].platform.architecture')
            echo $base_image_platforms_list
            while IFS= read -r line ; do 
                if [[ $ARCH == $line ]]; then 
                    supported=true
                    break
                fi 
            done <<< "$base_image_platforms_list"  
        else 
            supported=false
        fi

        if [[ !supported ]]; then
            rm -rf devfiles/"${dir}"
        fi
    done
done
#readarray -d '' devfiles < <(find "$1" -name 'devfile.yaml' -print0)




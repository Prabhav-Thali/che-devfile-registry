#!/bin/bash
#
# Copyright (c) 2020-2021 Red Hat, Inc.
# This program and the accompanying materials are made
# available under the terms of the Eclipse Public License 2.0
# which is available at https://www.eclipse.org/legal/epl-2.0/
#
# SPDX-License-Identifier: EPL-2.0
#

DEVFILES_DIR=$1
ARCH=$2
pip install yq

function handle_error() {
  the_image="$1"
  echo "  Could not read image metadata through skopeo inspect; skip $the_image"
  echo -n "  Reason: "
  sed 's|^|    |g' $LOG_FILE
}

for dir in devfiles/*/
do
    supported="false"
    dir=${dir%*/}
    echo "dir: $dir"
    for image in $(yq -r '.components[]?.image' "$dir/devfile.yaml" | grep -v "null" | sort | uniq); do
        echo "image: $image"
        if [[ $(skopeo inspect docker://"${image}" --raw | grep manifests) ]]; then
            base_image_platforms_list=$(skopeo inspect docker://"${image}" --raw | jq -r '.manifests[].platform.architecture')    
            echo $base_image_platforms_list
            echo "ARCH: $ARCH"
            #First image has support, it is made false to check for 2nd image. (can be set as default value again here)
            if [[ $supported == "true" ]]; then 
                supported=false
            fi
            while IFS= read -r line ; do 
                echo "line: $line"
                #If supported platforms contain Arch then make supported true and break from while
                if [[ $ARCH == $line ]]; then 
                    supported=true
                    break
                fi
            done <<< "$base_image_platforms_list"
            echo "Supported in IF: $supported"
            #if the platform is not supported then break
            if [[ "$supported" == "false" ]]; then
                break
            fi
        else
            echo "In else, setting supported false"
            supported=false
            break
        fi
    done
    echo "supported in outer else $supported"
    if [[ "$supported" == "false" ]]; then
        echo "directories deleted is: ${dir}"
        rm -rf devfiles/"${dir}"
    else
        echo "directory will be added ${dir}"
    fi
    
done
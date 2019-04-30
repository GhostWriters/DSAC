#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_docker_containers() {
    info "Getting docker container information"
    while IFS= read -r line; do
        IFS=' ' read -r -a ROW <<< "$line"
        local container_id=${ROW[0]}
        local container_image=${ROW[1]}
        local container_app=${ROW[1]##*/}
        if [[ ${containers[$container_app]+true} == "true" ]]; then
            warning "- $container_app already exists..."
        else
            # TODO: Convert this to a file, maybe
            info "- Adding $container_app to list."
            containers[$container_app]=$container_id
            containers_image[$container_app]=$container_image

            local TEMP=( $(docker container inspect ${container_id} | jq '.[0].Mounts[] | tostring') )
            for i in "${TEMP[@]}"; do
                local mounts=$(jq 'fromjson | .Destination' <<< "$i")
                mounts=${mounts//\"/}
                if [[ ${mounts} == "/config" ]]; then
                    config_source=$(jq 'fromjson | .Source' <<< "$i")
                    config_source=${config_source//\"/}
                    containers_config_path[$container_app]=${config_source}
                fi
            done
        fi
    done < <(sudo docker ps | awk '{if (NR>1) {print $1,$2}}')
}

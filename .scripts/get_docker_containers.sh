#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_docker_containers() {
    if [[ $(docker ps -q | wc -l) -gt 1 ]]; then
        notice "Getting docker container information"
        while IFS= read -r line; do
            local container_id=${line}
            local container_image
            local container_name
            local TEMP
            container_image=$(docker container inspect -f '{{ .Config.Image }}' "${container_id}")
            container_name=$(docker container inspect -f '{{ .Name }}' "${container_id}")
            container_name=${container_name//\//}

            if [[ ${containers[${container_name}]+true} == "true" ]]; then
                info "- ${container_name} already exists..."
            else
                info "- Adding ${container_name} to list."
                if [[ -f "${DETECTED_DSACDIR}/.data/${container_name}.json" ]]; then
                    containers[${container_name}]=$(cat "${DETECTED_DSACDIR}/.data/${container_name}.json")
                else
                    containers[${container_name}]=$(cat "${DETECTED_DSACDIR}/.data/template.json")
                fi
                containers[${container_name}]=$(jq --arg var "${container_id}" '.container_id = $var' <<< "${containers[${container_name}]}")
                containers[${container_name}]=$(jq --arg var "${container_image}" '.container_image = $var' <<< "${containers[${container_name}]}")
                containers[${container_name}]=$(jq '.is_docker = "true"' <<< "${containers[${container_name}]}")

                # Get container config path
                info "  Getting ${container_name} config path."
                mapfile -t TEMP < <(docker container inspect "${container_id}" | jq '.[0].Mounts[] | tostring')
                for i in "${TEMP[@]}"; do
                    local mounts
                    mounts=$(jq 'fromjson | .Destination' <<< "$i")
                    mounts=${mounts//\"/}
                    if [[ ${mounts} == "/config" ]]; then
                        config_source=$(jq 'fromjson | .Source' <<< "$i")
                        config_source=${config_source//\"/}
                        debug "  config_source=${config_source}"
                        containers[${container_name}]=$(jq --arg var "${config_source}" '.config.source = $var' <<< "${containers[${container_name}]}")
                    fi
                done
                # Get container ports
                info "  Getting ${container_name} port(s)."
                local port_original
                local port_configured
                mapfile -t TEMP < <(docker port "${container_id}")
                for port_mapping in "${TEMP[@]}"; do
                    port_original=$(awk '{split($1,a,"/"); print a[1]}' <<< "${port_mapping}")
                    port_configured=$(awk '{split($3,a,":"); print a[2]}' <<< "${port_mapping}")
                    containers[${container_name}]=$(jq --arg port1 "${port_original}" --arg port2 "${port_configured}" '.ports[$port1] = $port2' <<< "${containers[${container_name}]}")
                done
                if [[ ! -d "${DETECTED_DSACDIR}/.data/" ]]; then
                    mkdir -p "${DETECTED_DSACDIR}/.data/"
                fi
                #debug "containers[${container_name}]=${containers[${container_name}]}"
                echo "${containers[${container_name}]}" > "${DETECTED_DSACDIR}/.data/${container_name}.json"
            fi
        done < <(sudo docker ps -q)
    else
        error "You don't have any running docker containers."
        exit
    fi
}

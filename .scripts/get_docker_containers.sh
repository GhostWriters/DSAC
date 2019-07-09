#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_docker_containers() {
    info "Getting docker container information"
    while IFS= read -r line; do
        IFS=' ' read -r -a ROW <<< "$line"
        local container_id=${ROW[0]}
        local container_image=${ROW[1]}
        local container_name=${ROW[1]##*/}
        local TEMP

        if [[ ${containers[${container_name}]+true} == "true" ]]; then
            warning "- ${container_name} already exists..."
        else
            info "- Adding ${container_name} to list."
            containers[${container_name}]="{}"
            containers[${container_name}]=$(jq --arg var "${container_id}" '.container_id = $var' <<< "${containers[${container_name}]}")
            containers[${container_name}]=$(jq --arg var "${container_image}" '.container_image = $var' <<< "${containers[${container_name}]}")

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
                    containers[${container_name}]=$(jq --arg var "${config_source}" '.config_source = $var' <<< "${containers[${container_name}]}")
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
            #debug "containers[${container_name}]=${containers[${container_name}]}"
        fi
    done < <(sudo docker ps | awk '{if (NR>1) {print $1,$2}}')
}

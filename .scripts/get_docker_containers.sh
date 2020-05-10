#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_docker_containers() {
    if [[ $(docker ps -q | wc -l) -gt 1 ]]; then
        notice "Getting docker container information"
        while IFS= read -r line; do
            local CONTAINER_ID=${line}
            local CONTAINER_IMAGE
            CONTAINER_IMAGE=$(docker container inspect -f '{{ .Config.Image }}' "${CONTAINER_ID}")
            local CONTAINER_NAME
            CONTAINER_NAME=$(docker container inspect -f '{{ .Name }}' "${CONTAINER_ID}")
            CONTAINER_NAME=${CONTAINER_NAME//\//}
            local CONTAINER_YML
            CONTAINER_YML="services.${CONTAINER_NAME}.labels[com.dockstarter.dsac]"
            local CONTAINER_YML_FILE
            CONTAINER_YML_FILE="${DETECTED_DSACDIR}/.apps/${CONTAINER_NAME}/${CONTAINER_NAME}.labels.dsac.yml"

            notice "${CONTAINER_NAME}"
            if [[ -d "${DETECTED_DSACDIR}/.apps/${CONTAINER_NAME}" ]]; then
                DOCKER_NAME=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_name")
                info "DOCKER_NAME='${DOCKER_NAME}'"
                if [[ $(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_name") ]]; then
                    info "Updating information..."
                else
                    info "Adding information..."
                fi
            else
                warn "Could not find file for ${CONTAINER_NAME}. Skipping..."
                continue
            fi
            # Write container information to yml
            yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_name" "${CONTAINER_NAME}"
            yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_id" "${CONTAINER_ID}"
            yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_image" "${CONTAINER_IMAGE}"

            # Get container config path
            info "Getting ${CONTAINER_NAME} config path."
            mapfile -t MOUNTS < <(docker container inspect "${CONTAINER_ID}" | jq '.[0].Mounts[] | tostring')
            for i in "${MOUNTS[@]}"; do
                local MOUNT
                MOUNT=$(jq 'fromjson | .Destination' <<< "$i")
                MOUNT=${MOUNT//\"/}
                if [[ ${MOUNT} == "/config" ]]; then
                    local CONFIG_SOURCE
                    CONFIG_SOURCE=$(jq 'fromjson | .Source' <<< "$i")
                    CONFIG_SOURCE=${CONFIG_SOURCE//\"/}
                    debug "CONFIG_SOURCE=${CONFIG_SOURCE}"
                    yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.source" "${CONFIG_SOURCE}"
                fi
            done

            # Get container ports
            info "Getting ${CONTAINER_NAME} port(s)."
            local PORT_ORIGINAL
            local PORT_CONFIGURED
            mapfile -t PORTS < <(docker port "${CONTAINER_ID}")
            for PORT_MAPPING in "${PORTS[@]}"; do
                PORT_ORIGINAL=$(awk '{split($1,a,"/"); print a[1]}' <<< "${PORT_MAPPING}")
                PORT_CONFIGURED=$(awk '{split($3,a,":"); print a[2]}' <<< "${PORT_MAPPING}")
                yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.ports.${PORT_ORIGINAL}" "${PORT_CONFIGURED}"
            done

            containers[${CONTAINER_NAME}]=true
        done < <(sudo docker ps -q)
    else
        error "You don't have any running docker containers."
        exit
    fi
}

test_get_docker_containers() {
    warn "CI does not test this script"
}

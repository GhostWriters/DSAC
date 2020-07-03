#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_docker_containers() {

    if [[ -d "${DETECTED_DSACDIR}/.data/apps/" ]]; then
        info "Cleaning up existing container information"
        while IFS= read -r line; do
            local APPNAME=${line^^}
            local FILENAME=${APPNAME,,}
            local CONTAINER_YML
            CONTAINER_YML="services.${FILENAME}.labels[com.dockstarter.dsac]"
            if [[ -f ${DETECTED_DSACDIR}/.data/apps/${FILENAME}.yml ]]; then
                run_script 'yml_set' "${FILENAME}" "${CONTAINER_YML}.docker.running" "false"
            fi
        done < <(ls -A "${DETECTED_DSACDIR}/.data/apps/")
    fi

    if [[ $(docker ps -q | wc -l) -gt 1 ]]; then
        info "Scanning Docker for supported containers"
        while IFS= read -r line; do
            local CONTAINER_ID=${line}
            local CONTAINER_IMAGE
            CONTAINER_IMAGE=$(docker container inspect -f '{{ .Config.Image }}' "${CONTAINER_ID}")
            local CONTAINER_NAME
            CONTAINER_NAME=$(docker container inspect -f '{{ .Name }}' "${CONTAINER_ID}")
            CONTAINER_NAME=${CONTAINER_NAME//\//}
            local APPLICATION_NAME
            APPLICATION_NAME=${CONTAINER_IMAGE%%/*}
            APPLICATION_NAME=${APPLICATION_NAME%%:*}
            APPLICATION_NAME=${APPLICATION_NAME,,}
            local CONTAINER_YML
            CONTAINER_YML="services.${CONTAINER_NAME}.labels[com.dockstarter.dsac]"
            local CONTAINER_BASE_YML_FILE
            CONTAINER_BASE_YML_FILE="${DETECTED_DSACDIR}/.apps/${CONTAINER_NAME}/${CONTAINER_NAME}.labels.dsac.yml"
            local CONTAINER_YML_FILE
            CONTAINER_YML_FILE="${DETECTED_DSACDIR}/.data/apps/${CONTAINER_NAME}.yml"

            info "${APPLICATION_NAME^}"
            debug "CONTAINER_YML=${CONTAINER_YML}"
            debug "CONTAINER_BASE_YML_FILE=${CONTAINER_BASE_YML_FILE}"
            debug "CONTAINER_YML_FILE=${CONTAINER_YML_FILE}"
            if [[ -d "${DETECTED_DSACDIR}/.apps/${APPLICATION_NAME}" ]]; then
                # Check if the information needs to be added or updated
                if [[ -f ${CONTAINER_YML_FILE} ]]; then
                    info "Updating information..."
                else
                    info "Adding information..."
                    if [[ ! -d "${DETECTED_DSACDIR}/.data/apps/" ]]; then
                        mkdir -p "${DETECTED_DSACDIR}/.data/apps/"
                    fi
                    cp "${CONTAINER_BASE_YML_FILE}" "${CONTAINER_YML_FILE}"
                fi
            else
                info "${APPLICATION_NAME} not supported. Skipping..."
                continue
            fi
            # Write container information to yml
            run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.docker.container_name" "${CONTAINER_NAME}"
            run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.docker.container_id" "${CONTAINER_ID}"
            run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.docker.container_image" "${CONTAINER_IMAGE}"
            run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.docker.application_name" "${APPLICATION_NAME}"

            # Get container volume mounts
            info "Getting ${APPLICATION_NAME} config path."
            mapfile -t MOUNTS < <(docker container inspect "${CONTAINER_ID}" | jq '.[0].Mounts[] | tostring')
            for i in "${MOUNTS[@]}"; do
                local MOUNT
                MOUNT=$(jq 'fromjson | .Destination' <<< "$i")
                MOUNT=${MOUNT//\"/}
                # Get container config path
                if [[ ${MOUNT} == "/config" ]]; then
                    local CONFIG_SOURCE
                    CONFIG_SOURCE=$(jq 'fromjson | .Source' <<< "$i")
                    CONFIG_SOURCE=${CONFIG_SOURCE//\"/}
                    debug "CONFIG_SOURCE=${CONFIG_SOURCE}"
                    run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.config.source" "${CONFIG_SOURCE}"
                    # config path found. Time to move on.
                    break
                fi
            done

            # Get container ports
            info "Getting ${APPLICATION_NAME} port(s)."
            local PORT_ORIGINAL
            local PORT_CONFIGURED
            mapfile -t PORTS < <(docker port "${CONTAINER_ID}")
            for PORT_MAPPING in "${PORTS[@]}"; do
                PORT_ORIGINAL=$(awk '{split($1,a,"/"); print a[1]}' <<< "${PORT_MAPPING}")
                PORT_CONFIGURED=$(awk '{split($3,a,":"); print a[2]}' <<< "${PORT_MAPPING}")
                #yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.ports.${PORT_ORIGINAL}" "${PORT_CONFIGURED}"
                run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.ports.${PORT_ORIGINAL}" "${PORT_CONFIGURED}"
            done

            # Mark container as running
            run_script 'yml_set' "${APPLICATION_NAME}" "${CONTAINER_YML}.docker.running" "true"
        done < <(sudo docker ps -q)
    else
        error "You don't have any running docker containers."
        exit
    fi
}

test_get_docker_containers() {
    warn "CI does not test this script"
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_bazarr() {
    local CONTAINER_NAME=${1}
    # local db_path=${2}
    local CONFIG_PATH=${3}
    local CONTAINER_YML
    CONTAINER_YML="services.${CONTAINER_NAME}.labels[com.dockstarter.dsac]"

    if [[ $(run_script 'yml_get' "${CONTAINER_NAME}" "${CONTAINER_YML}.docker.running") == "true" ]]; then
        local LOCAL_IP
        LOCAL_IP=$(run_script 'detect_local_ip')
        local SONARR_CONTAINER_YML="services.sonarr.labels[com.dockstarter.dsac]"
        if [[ $(run_script 'yml_get' "sonarr" "${SONARR_CONTAINER_YML}.docker.running") == "true" ]]; then
            local SONARR_PORT
            SONARR_PORT=$(run_script 'yml_get' "sonarr" "${SONARR_CONTAINER_YML}.ports.default")
            SONARR_PORT=$(run_script 'yml_get' "sonarr" "${SONARR_CONTAINER_YML}.ports.${SONARR_PORT}" || echo "${SONARR_PORT}")
            crudini --set "${CONFIG_PATH}" sonarr apikey "${API_KEYS[sonarr]}"
            crudini --set "${CONFIG_PATH}" sonarr ip "${LOCAL_IP}"
            crudini --set "${CONFIG_PATH}" sonarr port "${sonarr_port}"
            crudini --set "${CONFIG_PATH}" general use_sonarr true
        fi
        local RADARR_CONTAINER_YML="services.sonarr.labels[com.dockstarter.dsac]"
        if [[ $(run_script 'yml_get' "radarr" "${RADARR_CONTAINER_YML}.docker.running") == "true" ]]; then
            local RADARR_PORT
            RADARR_PORT=$(run_script 'yml_get' "radarr" "${RADARR_CONTAINER_YML}.ports.default")
            RADARR_PORT=$(run_script 'yml_get' "radarr" "${RADARR_CONTAINER_YML}.ports.${RADARR_PORT}" || echo "${RADARR_PORT}")
            crudini --set "${CONFIG_PATH}" radarr apikey "${API_KEYS[radarr]}"
            crudini --set "${CONFIG_PATH}" radarr ip "${LOCAL_IP}"
            crudini --set "${CONFIG_PATH}" radarr port "${radarr_port}"
            crudini --set "${CONFIG_PATH}" general use_radarr true
        fi
    fi
}

test_configure_bazarr() {
    warn "CI does not test this script"
}

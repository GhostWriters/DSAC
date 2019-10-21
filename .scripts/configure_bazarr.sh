#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_bazarr() {
    local container_name=${1}
    # local db_path=${2}
    local config_path=${3}

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        local LOCAL_IP
        LOCAL_IP=$(run_script 'detect_local_ip')
        if [[ ${containers[sonarr]+true} == "true" ]]; then
            local sonarr_port
            sonarr_port=$(jq -r --arg port 8989 '.ports[$port]' <<< "${containers[sonarr]}")
            crudini --set "${config_path}" sonarr apikey "${API_KEYS[sonarr]}"
            crudini --set "${config_path}" sonarr ip "${LOCAL_IP}"
            crudini --set "${config_path}" sonarr port "${sonarr_port}"
            crudini --set "${config_path}" general use_sonarr true
        fi

        if [[ ${containers[radarr]+true} == "true" ]]; then
            local radarr_port
            radarr_port=$(jq -r --arg port 7878 '.ports[$port]' <<< "${containers[radarr]}")
            crudini --set "${config_path}" radarr apikey "${API_KEYS[radarr]}"
            crudini --set "${config_path}" radarr ip "${LOCAL_IP}"
            crudini --set "${config_path}" radarr port "${radarr_port}"
            crudini --set "${config_path}" general use_radarr true
        fi
    fi
}

test_configure_bazarr() {
    warn "CI does not test this script"
}

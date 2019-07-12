#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_subtitles_manager() {
    info "Configuring Subtitles Manager(s)"
    local container_name
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path
    container_name="bazarr"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
        config_source=$(jq -r '.config_source' <<< "${containers[${container_name}]}")
        config_file=$(jq -r '.config.file' <<< "${containers[${container_name}]}")
        db_file=$(jq -r '.config.database' <<< "${containers[${container_name}]}")
        config_path="${config_source}/${config_file}"
        db_path="${config_source}/${db_file}"
        container_id=$(jq -r '.container_id' <<< "${containers[${container_name}]}")
        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        debug "    db_path=${db_path}"
        cp "${db_path}" "${db_path}.dsac_bak"

        info "  - Stopping ${container_name} to apply changes..."
        docker stop "${container_id}" > /dev/null

        if [[ ${containers[sonarr]+true} == "true" ]]; then
            local sonarr_port
            sonarr_port=$(jq -r --arg port 8989 '.ports[$port]' <<< "${containers[sonarr]}")
            crudini --set "${config_path}" sonarr apikey ${API_KEYS[sonarr]}
            crudini --set "${config_path}" sonarr ip ${LOCAL_IP}
            crudini --set "${config_path}" sonarr port ${sonarr_port}
            crudini --set "${config_path}" general use_sonarr true
        fi

        if [[ ${containers[radarr]+true} == "true" ]]; then
            local radarr_port
            radarr_port=$(jq -r --arg port 7878 '.ports[$port]' <<< "${containers[radarr]}")
            crudini --set "${config_path}" radarr apikey ${API_KEYS[radarr]}
            crudini --set "${config_path}" radarr ip ${LOCAL_IP}
            crudini --set "${config_path}" radarr port ${radarr_port}
            crudini --set "${config_path}" general use_radarr true
        fi

        info "  - Starting ${container_name}..."
        docker start "${container_id}" > /dev/null
        info "  - Done"
    fi
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_music_manager() {
    info "Configuring Music Manager(s)"
    local container_name="lidarr"
    # shellcheck disable=SC2154
    local config_path
    # shellcheck disable=SC2154
    local db_path
    local config_file
    local db_file

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
        config_source=$(jq -r '.config_source' <<< "${containers[${container_name}]}")
        config_file=$(jq -r '.config.file' <<< "${containers[${container_name}]}")
        db_file=$(jq -r '.config.database' <<< "${containers[${container_name}]}")
        config_path="${config_source}/${config_file}"
        db_path="${config_source}/${db_file}"
        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        debug "    db_path=${db_path}"
        cp "${db_path}" "${db_path}.dsac_bak"

        run_script "configure_add_indexer" "$container_name" "${db_path}" "${config_path}"
        run_script "configure_add_downloader" "$container_name" "${db_path}" "${config_path}"
        info "  - Done"
    fi
}

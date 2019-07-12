#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_movies_manager() {
    info "Configuring Movie Manager(s)"
    local container_name
    local config_file
    local config_path
    local db_file
    local db_path
    container_name="radarr"

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

        run_script "configure_add_indexer" "$container_name" "${db_path}"
        run_script "configure_add_downloader" "$container_name" "${db_path}"
        info "  - Done"
    fi
}

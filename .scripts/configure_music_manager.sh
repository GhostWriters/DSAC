#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_music_manager() {
    info "Configuring Music Manager(s)"
    local container_name="lidarr"
    local config_file="config.xml"
    # shellcheck disable=SC2154
    local config_path="${containers_config_path[$container_name]}/${config_file}"
    local db_file="lidarr.db"
    # shellcheck disable=SC2154
    local db_path="${containers_config_path[$container_name]}/${db_file}"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
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

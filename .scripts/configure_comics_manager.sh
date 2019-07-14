#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_comics_manager() {
    info "Configuring Comics Manager(s)"
    local container_name
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path
    container_name="mylar"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
        config_source=$(jq -r '.config_source' <<< "${containers[${container_name}]}")
        config_file=$(jq -r '.config.file' <<< "${containers[${container_name}]}")
        db_file=$(jq -r '.config.database' <<< "${containers[${container_name}]}")
        container_id=$(jq -r '.container_id' <<< "${containers[${container_name}]}")
        config_path="${config_source}/${config_file}"
        db_path="${config_source}/${db_file}"
        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        debug "    db_path=${db_path}"
        cp "${db_path}" "${db_path}.dsac_bak"

        info "  - Stopping ${container_name} (${container_id}) to apply changes..."
        docker stop "${container_id}" > /dev/null

        run_script "configure_add_indexer" "$container_name" "${db_path}" "${config_path}"
        #run_script "configure_add_downloader" "$container_name" "${db_path}" "${config_path}"

        info "  - Starting ${container_name} (${container_id})..."
        docker start "${container_id}" > /dev/null
        info "  - Done"
    fi
}

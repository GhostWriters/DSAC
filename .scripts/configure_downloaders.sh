#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_downloaders() {
    info "Configuring Downloaders"
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path

    mapfile -t downloaders_categories < <(jq '.downloaders' "${DETECTED_DSACDIR}/.data/apps.json" | jq 'keys[]')
    for downloader_category_index in "${!downloaders_categories[@]}"; do
        downloader_category=${downloaders_categories[${downloader_category_index}]//\"/}
        info " - ${downloader_category} downloaders"
        mapfile -t downloaders < <(jq ".downloaders.${downloader_category}" "${DETECTED_DSACDIR}/.data/apps.json" | jq 'values[]')
        for downloader_index in "${!downloaders[@]}"; do
            downloader=${downloaders[${downloader_index}]//\"/}
            if [[ ${containers[$downloader]+true} == "true" ]]; then
                info "   - ${downloader}"
                container_id=$(jq -r '.container_id' <<< "${containers[${downloader}]}")
                config_source=$(jq -r '.config_source' <<< "${containers[${downloader}]}")
                config_file=$(jq -r '.config.file' <<< "${containers[${downloader}]}")
                db_file=$(jq -r '.config.database' <<< "${containers[${downloader}]}")

                if [[ ! -z "${config_file}" && ${config_file} != "null" ]]; then
                    config_path="${config_source}/${config_file}"
                    info "     - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
                    debug "       config_path=${config_path}"
                    cp "${config_path}" "${config_path}.dsac_bak"
                fi
                if [[ ! -z "${db_file}" && ${db_file} != "null" ]]; then
                    db_path="${config_source}/${db_file}"
                    info "     - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
                    debug "       db_path=${db_path}"
                    cp "${db_path}" "${db_path}.dsac_bak"
                fi

                info "     - Stopping ${downloader} (${container_id}) to apply changes..."
                docker stop "${container_id}" > /dev/null || error "       Unable to stop container..."

                run_script "configure_${downloader_category}_downloader" "${downloader}" "${db_path}" "${config_path}"

                info "     - Starting ${downloader} (${container_id})..."
                docker start "${container_id}" > /dev/null || error "       Unable to start container..."
                info "   - Done configuring ${downloader}"
            fi
        done
        info " - Done configuring ${downloader_category} downloaders"
    done
}

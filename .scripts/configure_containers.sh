#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_containers() {
    info "Configuring Containers"
    local app_type=${1}
    local app_category
    local app_name
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path

    mapfile -t app_categories < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/apps.json" | jq 'keys[]')
    for app_category_index in "${!app_categories[@]}"; do
        app_category=${app_categories[${app_category_index}]//\"/}
        info "- ${app_category} ${app_type}"
        mapfile -t apps < <(jq ".${app_type}.${app_category}" "${DETECTED_DSACDIR}/.data/apps.json" | jq 'values[]')
        for app_index in "${!apps[@]}"; do
            app_name=${apps[${app_index}]//\"/}
            if [[ ${containers[$app_name]+true} == "true" ]]; then
                info "  - ${app_name}"
                container_id=$(jq -r '.container_id' <<< "${containers[${app_name}]}")
                config_source=$(jq -r '.config_source' <<< "${containers[${app_name}]}")
                config_file=$(jq -r '.config.file' <<< "${containers[${app_name}]}")
                db_file=$(jq -r '.config.database' <<< "${containers[${app_name}]}")

                if [[ ! -z ${config_file} && ${config_file} != "null" ]]; then
                    config_path="${config_source}/${config_file}"
                    info "    - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
                    debug "      config_path=${config_path}"
                    cp "${config_path}" "${config_path}.dsac_bak"
                else
                    config_path=""
                fi
                if [[ ! -z ${db_file} && ${db_file} != "null" ]]; then
                    db_path="${config_source}/${db_file}"
                    info "    - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
                    debug "      db_path=${db_path}"
                    cp "${db_path}" "${db_path}.dsac_bak"
                else
                    db_path=""
                fi

                info "    - Stopping ${app_name} (${container_id}) to apply changes..."
                #docker stop "${container_id}" > /dev/null || error "       Unable to stop container..."

                if [[ ${app_name} == "bazarr" ]]; then
                    run_script "configure_${app_name}" "${app_name}" "${db_path}" "${config_path}"
                elif [[ ${app_category} == "usenet" || ${app_category} == "torrent" ]]; then
                    run_script "configure_${app_category}_downloader" "${app_name}" "${db_path}" "${config_path}"
                else
                    run_script "configure_add_indexer" "${app_name}" "${db_path}" "${config_path}"
                    run_script "configure_add_downloader" "${app_name}" "${db_path}" "${config_path}"
                fi

                info "    - Starting ${app_name} (${container_id})..."
                #docker start "${container_id}" > /dev/null || error "       Unable to start container..."
                info "  - Done configuring ${app_name}"
            fi
        done
        info "- Done configuring ${app_category} ${app_type}"
    done
}

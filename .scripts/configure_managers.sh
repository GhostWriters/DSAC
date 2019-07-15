#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_managers() {
    info "Configuring Managers"
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path

    mapfile -t managers_categories < <(jq '.managers' "${DETECTED_DSACDIR}/.data/apps.json" | jq 'keys[]')
    for manager_category_index in "${!managers_categories[@]}"; do
        manager_category=${managers_categories[${manager_category_index}]//\"/}
        info " - ${manager_category} managers"
        mapfile -t managers < <(jq ".managers.${manager_category}" "${DETECTED_DSACDIR}/.data/apps.json" | jq 'values[]')
        for manager_index in "${!managers[@]}"; do
            manager=${managers[${manager_index}]//\"/}
            if [[ ${containers[$manager]+true} == "true" ]]; then
                info "   - ${manager}"
                container_id=$(jq -r '.container_id' <<< "${containers[${manager}]}")
                config_source=$(jq -r '.config_source' <<< "${containers[${manager}]}")
                config_file=$(jq -r '.config.file' <<< "${containers[${manager}]}")
                db_file=$(jq -r '.config.database' <<< "${containers[${manager}]}")

                if [[ ! -z "${config_file}" && ${config_file} != "null" ]]; then
                    config_path="${config_source}/${config_file}"
                    info "     - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
                    debug "       config_path=${config_path}"
                    cp "${config_path}" "${config_path}.dsac_bak"
                else
                    config_path=""
                fi
                if [[ ! -z "${db_file}" && ${db_file} != "null" ]]; then
                    db_path="${config_source}/${db_file}"
                    info "     - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
                    debug "       db_path=${db_path}"
                    cp "${db_path}" "${db_path}.dsac_bak"
                else
                    db_path=""
                fi

                info "     - Stopping ${manager} (${container_id}) to apply changes..."
                docker stop "${manager}" > /dev/null || error "       Unable to stop container..."

                if [[ ${manager} = "bazarr" ]]; then
                    run_script "configure_${manager}" "${manager}" "${db_path}" "${config_path}"
                else
                    #run_script "configure_add_indexer" "${manager}" "${db_path}" "${config_path}"
                    #run_script "configure_add_downloader" "${manager}" "${db_path}" "${config_path}"
                fi

                info "     - Starting ${manager} (${container_id})..."
                docker start "${container_id}" > /dev/null || error "       Unable to start container..."
                info "   - Done configuring ${manager}"
            fi
        done
        info " - Done configuring ${manager_category} managers"
    done
}

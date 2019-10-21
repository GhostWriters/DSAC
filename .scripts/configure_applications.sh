#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_applications() {
    info "Configuring ${1} applications"
    local app_type=${1}
    local app_category
    local app_name
    local container_id
    local config_file
    local config_path
    local db_file
    local db_path
    local is_docker

    mapfile -t app_categories < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'keys[]')
    #shellcheck disable=SC2154
    for app_category_index in "${!app_categories[@]}"; do
        app_category=${app_categories[${app_category_index}]//\"/}
        if [[ ${app_type} == "indexers" || ${app_type} == "others" ]]; then
            mapfile -t apps < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'values[]')
            info "- ${app_type}"
        else
            mapfile -t apps < <(jq ".${app_type}.${app_category}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'values[]')
            info "- ${app_category} ${app_type}"
        fi
        for app_index in "${!apps[@]}"; do
            app_name=${apps[${app_index}]//\"/}
            if [[ ${containers[${app_name}]+true} == "true" ]]; then
                info "  - ${app_name}"
                container_id=$(jq -r '.container_id' <<< "${containers[${app_name}]}")
                config_source=$(jq -r '.config.source' <<< "${containers[${app_name}]}")
                config_file=$(jq -r '.config.file' <<< "${containers[${app_name}]}")
                db_file=$(jq -r '.config.database' <<< "${containers[${app_name}]}")
                is_docker=$(jq -r '.is_docker' <<< "${containers[${app_name}]}")

                if [[ -n ${config_file} && ${config_file} != "null" ]]; then
                    config_path="${config_source}/${config_file}"
                    # info "    - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
                    # debug "      config_path=${config_path}"
                    # cp "${config_path}" "${config_path}.dsac_bak"
                else
                    config_path=""
                fi
                if [[ -n ${db_file} && ${db_file} != "null" ]]; then
                    db_path="${config_source}/${db_file}"
                    # info "    - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
                    # debug "      db_path=${db_path}"
                    # cp "${db_path}" "${db_path}.dsac_bak"
                else
                    db_path=""
                fi

                if [[ ${is_docker} == "true" ]]; then
                    info "    - Stopping ${app_name} (${container_id}) to apply changes..."
                    docker stop "${container_id}" > /dev/null || error "       Unable to stop container..."
                fi

                if [[ ${app_name} == "bazarr" || ${app_name} == "hydra2" ]]; then
                    run_script "configure_${app_name}" "${app_name}" "${db_path}" "${config_path}"
                elif [[ ${app_category} == "usenet" || ${app_category} == "torrent" ]]; then
                    run_script "configure_${app_category}_downloader" "${app_name}" "${db_path}" "${config_path}"
                elif [[ ${app_type} == "indexers" ]]; then
                    debug "    - Not doing anything with ${app_name} right now..."
                else
                    run_script "configure_add_indexer" "${app_name}" "${db_path}" "${config_path}"
                    run_script "configure_add_downloader" "${app_name}" "${db_path}" "${config_path}"
                fi

                if [[ ${is_docker} == "true" ]]; then
                    info "    - Starting ${app_name} (${container_id})..."
                    docker start "${container_id}" > /dev/null || error "       Unable to start container..."
                fi
                info "  - Done configuring ${app_name}"
            fi
        done
        if [[ ${app_type} == "indexers" || ${app_type} == "others" ]]; then
            info "- Done configuring ${app_type}"
            break
        else
            info "- Done configuring ${app_category} ${app_type}"
        fi
    done
}

test_configure_applications() {
    warn "Test not configured yet."
}

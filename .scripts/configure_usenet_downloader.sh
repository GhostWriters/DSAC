#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_usenet_downloader() {
    info "Configuring Usenet Downloader(s)"
    local container_name
    local config_file
    local config_path
    local container_id
    container_name="nzbget"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
        config_source=$(jq -r '.config_source' <<< "${containers[${container_name}]}")
        config_file=$(jq -r '.config.file' <<< "${containers[${container_name}]}")
        config_path="${config_source}/${config_file}"
        container_id=$(jq -r '.container_id' <<< "${containers[${container_name}]}")

        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"

        info "  - Stopping ${container_name} to apply changes"
        docker stop "${container_id}" > /dev/null

        if [[ $(grep -c ".Name=Books" "${config_path}") -eq 0 ]]; then
            for ((i = 0; i <= 10; i++)); do
                local category
                category="Category${i}"
                if [[ $(grep -c "${category}.Name=" "${config_path}") -eq 0 ]]; then
                    info "  - Adding Books category..."
                    debug "    ${category}.Name=Books (DSAC)"
                    echo "${category}.Name=Books (DSAC)" >> "${config_path}"
                    echo "${category}.Aliases=Books" >> "${config_path}"
                    break
                fi
            done
        else
            debug "  - $(grep ".Name=Books" "${config_path}")"
        fi

        info "  - Starting ${container_name}..."
        docker start "${container_id}" > /dev/null
        info "  - Done"
    fi
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_usenet_downloader() {
    local container_name
    container_name="nzbget"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
        if [[ $(grep -c ".Name=Books" "${config_path}") -eq 0 ]]; then
            for ((i = 0; i <= 10; i++)); do
                local category
                category="Category${i}"
                #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
                if [[ $(grep -c "${category}.Name=" "${config_path}") -eq 0 ]]; then
                    info "    - Adding Books category..."
                    debug "    ${category}.Name=Books (DSAC)"
                    echo "${category}.Name=Books (DSAC)" >> "${config_path}"
                    echo "${category}.Aliases=Books" >> "${config_path}"
                    break
                fi
            done
        else
            debug "    - $(grep ".Name=Books" "${config_path}")"
        fi
    fi
}

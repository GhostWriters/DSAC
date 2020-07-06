#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_usenet_downloader() {
    local APPNAME=${1}
    # local db_path=${2}
    local APP_CONFIG_PATH=${3}
    local APP_CONTAINER_YML
    APP_CONTAINER_YML="services.${APPNAME}.labels[com.dockstarter.dsac]"

    # shellcheck disable=SC2154,SC2001
    if [[ $(run_script 'yml_get' "${APPNAME}" "${APP_CONTAINER_YML}.docker.running") == "true" ]]; then
        if [[ ${APPNAME} == "nzbget" ]]; then
            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
            if [[ $(grep -c ".Name=Books" "${APP_CONFIG_PATH}") -eq 0 ]]; then
                for ((i = 0; i <= 10; i++)); do
                    local category
                    category="Category${i}"
                    #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
                    if [[ $(grep -c "${category}.Name=" "${APP_CONFIG_PATH}") -eq 0 ]]; then
                        info "    - Adding Books category..."
                        debug "    ${category}.Name=Books (DSAC)"
                        echo "${category}.Name=Books (DSAC)" >> "${APP_CONFIG_PATH}"
                        echo "${category}.Aliases=Books" >> "${APP_CONFIG_PATH}"
                        break
                    fi
                done
            else
                debug "    - $(grep ".Name=Books" "${APP_CONFIG_PATH}")"
            fi
        fi
    fi
}

test_configure_usenet_downloader() {
    warn "CI does not test this script"
}

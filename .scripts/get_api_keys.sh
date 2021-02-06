#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

get_api_keys() {
    info "Retrieving API Keys"

    # shellcheck disable=SC2154
    while IFS= read -r line; do
        local APP_NAME=${line//.yml/}
        local CONFIG_FILE
        local CONFIG_PATH
        local API_KEY
        local restricted_user
        local restricted_pass
        local CONTAINER_YML

        info "${APP_NAME^}"
        CONTAINER_YML="services.${APP_NAME}.labels[com.dockstarter.dsac]"
        if [[ $(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.docker.running") == "true" ]]; then
            CONFIG_FILE=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.config.file")
            CONFIG_PATH=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.config.source")
            CONFIG_PATH_FULL="${CONFIG_PATH}/${CONFIG_FILE}"
            case "${APP_NAME}" in
                "nzbhydra2")
                    API_KEY=$(yq-go r "${CONFIG_PATH}" "main.apiKey")
                    API_KEY=${API_KEY// /}
                    API_KEYS[$APP_NAME]=${API_KEY}
                    debug "  ${API_KEYS[$APP_NAME]}"
                    ;;
                "jackett")
                    CONFIG_PATH_FULL="${CONFIG_PATH}/Jackett/${CONFIG_FILE}"
                    API_KEY=$(jq -r '.APIKey' "${CONFIG_PATH_FULL}")
                    API_KEY=${API_KEY// /}
                    API_KEYS[$APP_NAME]=${API_KEY}
                    debug "${API_KEYS[$APP_NAME]}"
                    ;;
                "nzbget")
                    restricted_user=$(grep 'RestrictedUsername=' "${CONFIG_PATH_FULL}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                    if [[ ${restricted_user} == "" ]]; then
                        restricted_user="dsac"
                        # TODO: Move this to the proper place for setting config
                        sed -i "s/RestrictedUsername=.*/RestrictedUsername=${restricted_user}/" "${CONFIG_PATH_FULL}"
                    fi
                    restricted_pass=$(grep 'RestrictedPassword=' "${CONFIG_PATH_FULL}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                    if [[ ${restricted_pass} == "" ]]; then
                        restricted_pass=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
                        # TODO: Move this to the proper place for setting config
                        sed -i "s/RestrictedPassword=.*/RestrictedPassword=${restricted_pass}/" "${CONFIG_PATH_FULL}"
                    fi
                    API_KEY="${restricted_user},${restricted_pass}"
                    API_KEYS[$APP_NAME]=${API_KEY}
                    debug "${API_KEYS[$APP_NAME]}"
                    ;;
                "radarr" | "sonarr" | "lidarr")
                    API_KEY=$(grep '<ApiKey>' "${CONFIG_PATH_FULL}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                    API_KEY=${API_KEY// /}
                    API_KEYS[$APP_NAME]=${API_KEY}
                    debug "${API_KEYS[$APP_NAME]}"
                    ;;
                "portainer" | "heimdall" | "qbittorrent" | "mylar" | "lazylibrarian" | "bazarr" | "couchpotato")
                    debug "API Key currently not needed"
                    ;;
                *)
                    debug "No API Key retrieval configured"
                    ;;
            esac
            if [[ ${API_KEY:-} != "" ]]; then
                run_script 'yml_set' "${APP_NAME}" "${CONTAINER_YML}.data.api_key" "${API_KEY}"
            fi
        fi
    done < <(ls -A "${DETECTED_DSACDIR}/.data/apps/")
}

test_get_api_keys() {
    warn "CI does not test this script"
}

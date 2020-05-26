#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_api_keys() {
    info "Retrieving API Keys"

    # shellcheck disable=SC2154
    # TODO: Change this to use the .data/apps directory
    # TODO: Output API Keys to YML?
    for CONTAINER_NAME in "${!containers[@]}"; do
        local CONFIG_FILE
        local CONFIG_PATH
        local API_KEY
        local restricted_user
        local restricted_pass
        local CONTAINER_YML
        local CONTAINER_YML_FILE

        info "- ${CONTAINER_NAME}"
        CONTAINER_YML="services.${CONTAINER_NAME}.labels[com.dockstarter.dsac]"
        CONTAINER_YML_FILE="${DETECTED_DSACDIR}/.data/apps/${CONTAINER_NAME}.yml"
        CONFIG_FILE=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.file")
        CONFIG_PATH=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.source")
        CONFIG_PATH_FULL="${CONFIG_PATH}/${CONFIG_FILE}"
        case "${CONTAINER_NAME}" in
            "nzbhydra2")
                API_KEY=$(yq-go r "${CONFIG_PATH}" "main.apiKey")
                API_KEY=${API_KEY// /}
                API_KEYS[$CONTAINER_NAME]=${API_KEY}
                debug "  ${API_KEYS[$CONTAINER_NAME]}"
                ;;
            "jackett")
                CONFIG_PATH_FULL="${CONFIG_PATH}/Jackett/${CONFIG_FILE}"
                API_KEY=$(jq -r '.APIKey' "${CONFIG_PATH_FULL}")
                API_KEY=${API_KEY// /}
                API_KEYS[$CONTAINER_NAME]=${API_KEY}
                debug "  ${API_KEYS[$CONTAINER_NAME]}"
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
                API_KEYS[$CONTAINER_NAME]=${API_KEY}
                debug "  ${API_KEYS[$CONTAINER_NAME]}"
                ;;
            "radarr" | "sonarr" | "lidarr")
                API_KEY=$(grep '<ApiKey>' "${CONFIG_PATH_FULL}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                API_KEY=${API_KEY// /}
                API_KEYS[$CONTAINER_NAME]=${API_KEY}
                debug "  ${API_KEYS[$CONTAINER_NAME]}"
                ;;
            "portainer" | "heimdall" | "qbittorrent" | "mylar" | "lazylibrarian" | "bazarr" | "couchpotato")
                trace "  API Key currently not needed"
                ;;
            *)
                trace "  No API Key retrieval configured"
                ;;
        esac
        if [[ ${API_KEY:-} != "" ]]; then
            yq-go w -i "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.data.api_key" "${API_KEY}"
        fi
    done
}

test_get_api_keys() {
    warn "CI does not test this script"
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_api_keys() {
    info "Retrieving API Keys"

    # shellcheck disable=SC2154
    for container_name in "${!containers[@]}"; do
        local config_file
        local config_path
        local API_KEY
        local restricted_user
        local restricted_pass

        info "- ${container_name}"
        case "${container_name}" in
            "hydra2")
                config_file="nzbhydra.yml"
                config_path=$(jq -r '.config_source' <<< "${containers[$container_name]}")
                config_path="${config_path}/${config_file}"
                API_KEY=$(yq r "${config_path}" main.apiKey)
                API_KEY=${API_KEY// /}
                API_KEYS[$container_name]=${API_KEY}
                debug "  ${API_KEYS[$container_name]}"
                ;;
            "nzbget")
                config_file="nzbget.conf"
                config_path=$(jq -r '.config_source' <<< "${containers[$container_name]}")
                config_path="${config_path}/${config_file}"
                restricted_user=$(grep 'RestrictedUsername=' "${config_path}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                if [[ ${restricted_user} == "" ]]; then
                    restricted_user="dsac"
                    # TODO: Move this to the proper place for setting config
                    sed -i "s/RestrictedUsername=.*/RestrictedUsername=${restricted_user}/" "${config_path}"
                fi
                restricted_pass=$(grep 'RestrictedPassword=' "${config_path}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                if [[ ${restricted_pass} == "" ]]; then
                    restricted_pass=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
                    # TODO: Move this to the proper place for setting config
                    sed -i "s/RestrictedPassword=.*/RestrictedPassword=${restricted_pass}/" "${config_path}"
                fi
                API_KEY="${restricted_user},${restricted_pass}"
                API_KEYS[$container_name]=${API_KEY}
                debug "  ${API_KEYS[$container_name]}"
                ;;
            "radarr"|"sonarr"|"lidarr")
                config_file="config.xml"
                config_path=$(jq -r '.config_source' <<< "${containers[$container_name]}")
                config_path="${config_path}/${config_file}"
                API_KEY=$(grep '<ApiKey>' "${config_path}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                API_KEY=${API_KEY// /}
                API_KEYS[$container_name]=${API_KEY}
                debug "  ${API_KEYS[$container_name]}"
                ;;
            *)
                warning "  No API Key retrieval configured for ${container_name}"
                ;;
        esac
        # shellcheck disable=SC2034
        containers[$container_name]=$(jq --arg var "${API_KEY}" '.api_key = $var' <<< "${containers[$container_name]}")
        debug "  containers[$container_name]=${containers[$container_name]}"
    done
}

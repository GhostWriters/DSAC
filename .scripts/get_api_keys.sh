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

        case "${container_name}" in
            "hydra2")
                info "- ${container_name}"
                config_file="nzbhydra.yml"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                API_KEY=$(yq r "${config_path}" main.apiKey)
                API_KEYS[$container_name]=${API_KEY// /}
                debug "  ${API_KEYS[$container_name]}"
                ;;
            "nzbget")
                info "- ${container_name}"
                config_file="nzbget.conf"
                config_path="${containers_config_path[$container_name]}/${config_file}"
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
                API_KEYS[$container_name]="${restricted_user},${restricted_pass}"
                debug "  ${API_KEYS[$container_name]}"
                ;;
            "radarr"|"sonarr"|"lidarr")
                info "- ${container_name}"
                config_file="config.xml"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                API_KEY=$(grep '<ApiKey>' "${config_path}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                API_KEYS[$container_name]=${API_KEY// /}
                debug "  ${API_KEYS[$container_name]}"
                ;;
            *)
                warning "- No API Key retrieval configured for ${container_name}"
                ;;
        esac
    done
}

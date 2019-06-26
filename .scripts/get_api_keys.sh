#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_api_keys() {
    info "Retrieving API Keys"

    for i in "${!containers[@]}"; do
        local container_name="$i"
        local container_id="${containers[$i]}"
        local config_file
        local config_path
        local db_file
        local db_path

        case "${container_name}" in
            "hydra2")
                info "- Hydra2"
                config_file="nzbhydra.yml"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                local API_KEY=$(grep 'apiKey:' "${config_path}" | sed -e 's/apiKey:.*"\(.*\)"/\1/')
                API_KEYS[$container_name]=${API_KEY// /}
                debug "${API_KEYS[$container_name]}"
                ;;
            "nzbget")
                info "- NZBget"
                config_file="nzbget.conf"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                local restricted_user=$(grep 'RestrictedUsername=' "${config_path}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                if [[ ${restricted_user} == "" ]]; then
                    restricted_user="dsac"
                    # TODO: Move this to the proper place for setting config
                    sed -i "s/RestrictedUsername=.*/RestrictedUsername=${restricted_user}/" "${config_path}"
                fi
                local restricted_pass=$(grep 'RestrictedPassword=' "${config_path}" | sed -e 's/Restricted.*=\(.*\)/\1/')
                if [[ ${restricted_pass} == "" ]]; then
                    restricted_pass=$(uuidgen | tr -d - | tr -d '' | tr '[:upper:]' '[:lower:]')
                    # TODO: Move this to the proper place for setting config
                    sed -i "s/RestrictedPassword=.*/RestrictedPassword=${restricted_pass}/" "${config_path}"
                fi
                API_KEYS[$container_name]="${restricted_user},${restricted_pass}"
                debug "${API_KEYS[$container_name]}"
                ;;
            "radarr")
                info "- Radarr"
                config_file="config.xml"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                local API_KEY=$(grep '<ApiKey>' "${config_path}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                API_KEYS[$container_name]=${API_KEY// /}
                debug "${API_KEYS[$container_name]}"
                ;;
            "sonarr")
                info "- Sonarr"
                config_file="config.xml"
                config_path="${containers_config_path[$container_name]}/${config_file}"
                local API_KEY=$(grep '<ApiKey>' "${config_path}" | sed -e 's/<ApiKey>\(.*\)<\/ApiKey>/\1/')
                API_KEYS[$container_name]=${API_KEY// /}
                debug "${API_KEYS[$container_name]}"
                ;;
            *)
                warning "- No API Key retrieval configured for ${container_name}"
                ;;
        esac
    done
}

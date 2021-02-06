#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

configure_torrent_downloader() {
    local APPNAME=${1}
    # local db_path=${2}
    local APP_CONFIG_PATH=${3}
    local APP_CONTAINER_YML
    APP_CONTAINER_YML="services.${APPNAME}.labels[com.dockstarter.dsac]"

    # shellcheck disable=SC2154,SC2001
    if [[ $(run_script 'yml_get' "${APPNAME}" "${APP_CONTAINER_YML}.docker.running") == "true" ]]; then
        local CONTAINER_ID
        CONTAINER_ID=$(run_script 'yml_get' "${APPNAME}" "${APP_CONTAINER_YML}.docker.container_id")
        if [[ ${APPNAME} == "qbittorrent" ]]; then
            local CONTAINER_NETWORK
            CONTAINER_NETWORK=$(docker container inspect "${CONTAINER_ID}" | jq '.[0].NetworkSettings.Networks | to_entries[].key' | awk '{gsub("\"",""); print}')
            debug "    CONTAINER_NETWORK=${CONTAINER_NETWORK}"
            local NETWORK_SUBNET
            NETWORK_SUBNET=$(docker network inspect "${CONTAINER_NETWORK}" | jq '.[0].IPAM.Config[0].Subnet' | awk '{gsub("\"",""); split($0,a,"/"); print a[1]}')
            debug "    NETWORK_SUBNET=${NETWORK_SUBNET}"

            local IP_ADDRESSES_NEW
            IP_ADDRESSES_NEW=("${NETWORK_SUBNET}/24")
            debug "    IP_ADDRESSES_NEW=${IP_ADDRESSES_NEW[*]}"

            local IP_ADDRESSES_CURRENT
            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
            if [[ $(grep -c "AuthSubnetWhitelist=" "${APP_CONFIG_PATH}") -gt 0 ]]; then
                IP_ADDRESSES_CURRENT="$(grep "AuthSubnetWhitelist=" "${APP_CONFIG_PATH}")"
                IP_ADDRESSES_CURRENT=${IP_ADDRESSES_CURRENT#*=}
                IP_ADDRESSES_CURRENT=${IP_ADDRESSES_CURRENT// /}

                debug "    Building new IP Address list"
                IFS="," read -ra IP_ADDRESSES_CURRENT <<< "${IP_ADDRESSES_CURRENT}"
                local MATCH
                for IP_CURRENT in "${IP_ADDRESSES_CURRENT[@]}"; do
                    MATCH="false"
                    for IP_NEW in "${IP_ADDRESSES_NEW[@]}"; do
                        if [[ ${IP_CURRENT} == "${IP_NEW}" ]]; then
                            MATCH="true"
                            break
                        fi
                    done

                    if [[ ${MATCH} == "false" && ${IP_CURRENT} != "@Invalid()" ]]; then
                        IP_ADDRESSES_NEW+=("${IP_CURRENT}")
                    fi
                done
            else
                IP_ADDRESSES_CURRENT=()
            fi

            debug "    IP_ADDRESSES_NEW=${IP_ADDRESSES_NEW[*]}"
            printf -v IP_ADDRESSES "%s," "${IP_ADDRESSES_NEW[@]}" 2> /dev/null
            debug "    IP_ADDRESSES=${IP_ADDRESSES}"
            info "    - Adding docker network to the list..."
            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
            if [[ $(grep -c "AuthSubnetWhitelist=" "${APP_CONFIG_PATH}") -gt 0 ]]; then
                debug "    Updating AuthSubnetWhitelist"
                sed -i "s#AuthSubnetWhitelist=.*#AuthSubnetWhitelist=${IP_ADDRESSES}#" "${APP_CONFIG_PATH}"
            else
                debug "    Adding AuthSubnetWhitelist"
                echo "WebUI\AuthSubnetWhitelist=${IP_ADDRESSES}" >> "${APP_CONFIG_PATH}"
            fi
            info "    - Enabling authentication bypass for local docker network..."
            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
            if [[ $(grep -c "AuthSubnetWhitelistEnabled=" "${APP_CONFIG_PATH}") -gt 0 ]]; then
                debug "    Updating AuthSubnetWhitelistEnabled"
                sed -i "s/AuthSubnetWhitelistEnabled=.*/AuthSubnetWhitelistEnabled=true/" "${APP_CONFIG_PATH}"
            else
                debug "    Adding AuthSubnetWhitelistEnabled"
                echo "WebUI\AuthSubnetWhitelistEnabled=true" >> "${APP_CONFIG_PATH}"
            fi
        fi
    fi
}

test_configure_torrent_downloader() {
    warn "CI does not test this script"
}

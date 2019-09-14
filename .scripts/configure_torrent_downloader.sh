#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_torrent_downloader() {
    local app_name="qbittorrent"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[${app_name}]+true} == "true" ]]; then
        local is_docker
        is_docker=$(jq -r '.is_docker' <<< "${containers[${app_name}]}")

        if [[ ${is_docker} == true ]]; then
            local container_network
            container_network=$(docker container inspect "${container_id}" | jq '.[0].NetworkSettings.Networks | to_entries[].key' | awk '{gsub("\"",""); print}')
            debug "    container_network=${container_network}"
            local network_subnet
            network_subnet=$(docker network inspect "${container_network}" | jq '.[0].IPAM.Config[0].Subnet' | awk '{gsub("\"",""); split($0,a,"/"); print a[1]}')
            debug "    network_subnet=${network_subnet}"
        fi

        local ip_addresses_new
        ip_addresses_new=("${network_subnet}/24")
        debug "    ip_addresses_new=${ip_addresses_new[*]}"

        local ip_addresses_current
        #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
        if [[ $(grep -c "AuthSubnetWhitelist=" "${config_path}") -gt 0 ]]; then
            ip_addresses_current="$(grep "AuthSubnetWhitelist=" "${config_path}")"
            ip_addresses_current=${ip_addresses_current#*=}
            ip_addresses_current=${ip_addresses_current// /}

            debug "    Building new IP Address list"
            IFS="," read -ra ip_addresses_current <<< "${ip_addresses_current}"
            local match
            for ip_current in "${ip_addresses_current[@]}"; do
                match="false"
                for ip_new in "${ip_addresses_new[@]}"; do
                    if [[ ${ip_current} == "${ip_new}" ]]; then
                        match="true"
                        break
                    fi
                done

                if [[ ${match} == "false" && ${ip_current} != "@Invalid()" ]]; then
                    ip_addresses_new+=("${ip_current}")
                fi
            done
        else
            ip_addresses_current=()
        fi

        debug "    ip_addresses_new=${ip_addresses_new[*]}"
        printf -v ip_addresses "%s," "${ip_addresses_new[@]}" 2> /dev/null
        debug "    ip_addresses=${ip_addresses}"
        info "    - Adding docker network to the list..."
        #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
        if [[ $(grep -c "AuthSubnetWhitelist=" "${config_path}") -gt 0 ]]; then
            debug "    Updating AuthSubnetWhitelist"
            sed -i "s#AuthSubnetWhitelist=.*#AuthSubnetWhitelist=${ip_addresses}#" "${config_path}"
        else
            debug "    Adding AuthSubnetWhitelist"
            echo "WebUI\AuthSubnetWhitelist=${ip_addresses}" >> "${config_path}"
        fi
        info "    - Enabling authentication bypass for local docker network..."
        #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
        if [[ $(grep -c "AuthSubnetWhitelistEnabled=" "${config_path}") -gt 0 ]]; then
            debug "    Updating AuthSubnetWhitelistEnabled"
            sed -i "s/AuthSubnetWhitelistEnabled=.*/AuthSubnetWhitelistEnabled=true/" "${config_path}"
        else
            debug "    Adding AuthSubnetWhitelistEnabled"
            echo "WebUI\AuthSubnetWhitelistEnabled=true" >> "${config_path}"
        fi
    fi
}

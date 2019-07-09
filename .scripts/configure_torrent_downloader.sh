#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_torrent_downloader() {
    info "Configuring Torrent Downloader(s)"
    local container_name
    local config_file
    local config_path
    local container_id
    container_name="qbittorrent"
    config_file="qBittorrent.conf"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- ${container_name}"
        config_source=$(jq -r '.config_source' <<< "${containers[${container_name}]}")
        config_path="${config_source}/qBittorrent/${config_file}"
        container_id=$(jq -r '.container_id' <<< "${containers[${container_name}]}")

        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"

        local container_network
        container_network=$(docker container inspect "${container_id}" | jq '.[0].NetworkSettings.Networks | to_entries[].key' | awk '{gsub("\"",""); print}')
        debug "    container_network=${container_network}"
        local network_subnet
        network_subnet=$(docker network inspect "${container_network}" | jq '.[0].IPAM.Config[0].Subnet' | awk '{gsub("\"",""); split($0,a,"/"); print a[1]}')
        debug "    network_subnet=${network_subnet}"

        local ip_addresses_new
        ip_addresses_new=("${network_subnet}/24")

        local ip_addresses_current
        ip_addresses_current="$(grep "AuthSubnetWhitelist=" "${config_path}")"
        ip_addresses_current=${ip_addresses_current#*=}
        ip_addresses_current=${ip_addresses_current// /}

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

            if [[ ${match} == "false" ]]; then
                ip_addresses_new+=("${ip_current}")
            fi
        done
        debug "    ip_addresses_new=${ip_addresses_new[*]}"
        printf -v ip_addresses "%s," "${ip_addresses_new[@]}" 2> /dev/null
        debug "    ip_addresses=${ip_addresses}"
        info "  - Enabling authentication bypass for local docker network..."
        sed -i "s/AuthSubnetWhitelistEnabled=.*/AuthSubnetWhitelistEnabled=true/" "${config_path}"
        info "  - Adding docker network to the list..."
        sed -i "s#AuthSubnetWhitelist=.*#AuthSubnetWhitelist=${ip_addresses}#" "${config_path}"

        info "  - Restarting ${container_name} to apply changes"
        docker restart "${container_id}" > /dev/null
        info "  - Done"
    fi
}

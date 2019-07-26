#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_indexer() {
    info "    - Updating Indexer settings"
    local container_name="${1}"
    local db_path="${2}"
    local config_path="${3}"
    local indexer_configured="false"
    local hydra2_configured="false"
    debug "      container_name=${container_name}"
    debug "      db_path=${db_path}"
    debug "      config_path=${config_path}"
    # Define supported indexers and their default listening port
    typeset -A indexer_names
    typeset -A indexer_port
    indexer_names[0]="hydra2"
    indexer_names[1]="jackett"
    indexer_ports[0]="5076"
    indexer_ports[1]="9117"

    for index in "${!indexer_names[@]}"; do
        local indexer
        indexer=${indexer_names[$index]}

        # shellcheck disable=SC2154,SC2001
        if [[ ${containers[${indexer}]+true} == "true" ]]; then
            local indexer_port
            local indexer_base
            local LOCAL_IP
            LOCAL_IP=$(run_script 'detect_local_ip')
            if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" || ${container_name} == "lidarr" ]]; then
                if [[ ${indexer} == "hydra2" || (${indexer} == "jackett" && ${hydra2_configured} != "true") ]]; then
                    info "      - Linking ${container_name} to ${indexer}..."
                    local indexer_db_id
                    local indexer_settings
                    local categories
                    local additional_columns
                    local additional_values
                    indexer_base=$(jq -r '.base_url' <<< "${containers[${indexer}]}")
                    indexer_port=$(jq -r --arg port "${indexer_ports[$index]}" '.ports[$port]' <<< "${containers[${indexer}]}")
                    indexer_url_base="http://${LOCAL_IP}:${indexer_port}${indexer_base}"

                    if [[ ${container_name} == "radarr" ]]; then
                        categories="2000,2010,2020,2030,2035,2040,2045,2050,2060"
                    elif [[ ${container_name} == "sonarr" ]]; then
                        categories="5030,5040"
                    elif [[ ${container_name} == "lidarr" ]]; then
                        categories="3000,3010,3020,3030,3040"
                    else
                        categories=""
                        warning "      No categories configured for ${container_name}"
                    fi
                    debug "        container_name=${container_name}"
                    debug "        categories=${categories}"

                    if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" ]]; then
                        additional_columns=",EnableSearch"
                        additional_values=",1"
                    elif [[ ${container_name} == "lidarr" ]]; then
                        additional_columns=",EnableAutomaticSearch,EnableInteractiveSearch"
                        additional_values=",1,1"
                    else
                        additional_columns=""
                        additional_values=""
                    fi

                    local indexer_type
                    if [[ ${indexer} == "hydra2" ]]; then
                        indexer_type=("torrent" "usenet")
                    elif [[ ${indexer} == "jackett" ]]; then
                        indexer_type=("torrent")
                    else
                        indexer_type=("torrent")
                    fi

                    for type in "${indexer_type[@]}"; do
                        local indexer_url
                        local indexer_name
                        debug "        Indexer type: ${type}"

                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            config_contract="NewznabSettings"
                            indexer_name="${indexer} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            config_contract="TorznabSettings"
                            indexer_name="${indexer} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${indexer_base} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                        else
                            fatal "        ${indexer} not supported and this shouldn't have happened..."
                        fi
                        sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss${additional_columns})
                                                SELECT '${indexer_name}','${implementation}','{
                                                        \"baseUrl\": \"${indexer_url}\",
                                                        \"multiLanguages\": [],
                                                        \"apiKey\": \"${API_KEYS[${indexer}]}\",
                                                        \"categories\": [${categories}],
                                                        \"animeCategories\": [],
                                                        \"removeYear\": false,
                                                        \"searchByTitle\": false }','${config_contract}',1${additional_values}
                                                WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='${indexer_name}');"
                        debug "        Get ${indexer} DB ID"
                        indexer_db_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='${indexer_name}'")
                        debug "        ${indexer} DB ID: ${indexer_db_id}"
                        # Get settings for indexer
                        indexer_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$indexer_db_id")
                        # Set indexer API Key
                        debug "        Setting API Key to: ${API_KEYS[${indexer}]}"
                        indexer_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[${indexer}]}"'",/' <<< "$indexer_settings")
                        # Set indexer Url
                        debug "        Setting URL to: ${indexer_url}"
                        indexer_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${indexer_url}"'",#' <<< "$indexer_settings")
                        # Set categories
                        debug "        Setting categories to: [${categories}]"
                        indexer_settings=$(sed 's#"categories":.*,#"categories": ['"${categories}"'],#' <<< "$indexer_settings")
                        #Update the settings for indexer
                        debug "        Updating DB"
                        sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$indexer_settings' WHERE id=$indexer_db_id"
                    done

                    if [[ ${indexer} == "hydra2" ]]; then
                        hydra2_configured="true"
                    fi

                    indexer_configured="true"
                fi
            fi

            if [[ ${container_name} == "lazylibrarian" ]]; then
                if [[ ${indexer} == "hydra2" || (${indexer} == "jackett" && ${hydra2_configured} != "true") ]]; then
                    info "      - Linking ${container_name} to ${indexer}..."
                    indexer_base=$(jq -r '.base_url' <<< "${containers[${indexer}]}")
                    indexer_port=$(jq -r --arg port "${indexer_ports[$index]}" '.ports[$port]' <<< "${containers[${indexer}]}")
                    indexer_url_base="http://${LOCAL_IP}:${indexer_port}${indexer_base}"

                    local indexer_type
                    if [[ ${indexer} == "hydra2" ]]; then
                        indexer_type=("torrent" "usenet")
                    elif [[ ${indexer} == "jackett" ]]; then
                        indexer_type=("torrent")
                    else
                        fatal "        ${indexer} not supported and this shouldn't have happened..."
                    fi

                    for type in "${indexer_type[@]}"; do
                        local indexer_url
                        local indexer_name
                        local indexer_section
                        indexer_section=""

                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            indexer_name="${indexer} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            indexer_name="${indexer} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${indexer_base} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                        else
                            fatal "        ${type} not supported and this shouldn't have happened..."
                        fi

                        for ((i = 0; i <= 10; i++)); do
                            debug "        Checking ${implementation}${i}..."
                            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
                            if [[ $(grep -c "${implementation}${i}" "${config_path}") -gt 0 ]]; then
                                local indexer_name_check
                                indexer_name_check=$(crudini --get "${config_path}" "${implementation}${i}" dispname)
                                if [[ ${indexer_name_check} == "${indexer_name}" ]]; then
                                    indexer_section="${implementation}${i}"
                                    debug "        - Updating ${indexer_name}..."
                                    break
                                fi
                            elif [[ -z ${indexer_section} ]]; then
                                indexer_section="${implementation}${i}"
                                debug "        - Adding ${indexer_name}..."
                                break
                            fi
                        done

                        if [[ -n ${indexer_section} ]]; then
                            crudini --set "${config_path}" "${indexer_section}" comicsearch
                            crudini --set "${config_path}" "${indexer_section}" audiocat 3030
                            crudini --set "${config_path}" "${indexer_section}" extended 1
                            crudini --set "${config_path}" "${indexer_section}" manual 0
                            crudini --set "${config_path}" "${indexer_section}" bookcat 7000,7020
                            crudini --set "${config_path}" "${indexer_section}" enabled True
                            crudini --set "${config_path}" "${indexer_section}" magcat 7010
                            crudini --set "${config_path}" "${indexer_section}" comiccat 7030
                            crudini --set "${config_path}" "${indexer_section}" dltypes A,C,E,M
                            crudini --set "${config_path}" "${indexer_section}" generalsearch search
                            # Set indexer Url
                            debug "        Setting URL to: ${indexer_url}"
                            crudini --set "${config_path}" "${indexer_section}" host "${indexer_url}"
                            # Set indexer API key
                            debug "        Setting API Key to: ${API_KEYS[${indexer}]}"
                            crudini --set "${config_path}" "${indexer_section}" api "${API_KEYS[${indexer}]}"
                            crudini --set "${config_path}" "${indexer_section}" apilimit 0
                            crudini --set "${config_path}" "${indexer_section}" booksearch book
                            crudini --set "${config_path}" "${indexer_section}" apicount 0
                            crudini --set "${config_path}" "${indexer_section}" dlpriority 0
                            crudini --set "${config_path}" "${indexer_section}" magsearch
                            crudini --set "${config_path}" "${indexer_section}" audiosearch
                            crudini --set "${config_path}" "${indexer_section}" dispname "${indexer_name}"
                        else
                            error "      Unable to link ${container_name} to ${indexer}..."
                            error "      You probably have too many providers configured."
                        fi
                    done

                    if [[ ${indexer} == "hydra2" ]]; then
                        hydra2_configured="true"
                    fi

                    indexer_configured="true"
                fi
            fi

            if [[ ${container_name} == "mylar" ]]; then
                if [[ ${indexer} == "hydra2" || (${indexer} == "jackett" && ${hydra2_configured} != "true") ]]; then
                    info "      - Linking ${container_name} to ${indexer}..."
                    indexer_base=$(jq -r '.base_url' <<< "${containers[${indexer}]}")
                    indexer_port=$(jq -r --arg port "${indexer_ports[$index]}" '.ports[$port]' <<< "${containers[${indexer}]}")
                    indexer_url_base="http://${LOCAL_IP}:${indexer_port}${indexer_base}"

                    local indexer_type
                    if [[ ${indexer} == "hydra2" ]]; then
                        indexer_type=("torrent" "usenet")
                    elif [[ ${indexer} == "jackett" ]]; then
                        indexer_type=("torrent")
                    else
                        fatal "        ${indexer} not supported and this shouldn't have happened..."
                    fi

                    for type in "${indexer_type[@]}"; do
                        local indexer_url
                        local indexer_name
                        local indexer_section=""
                        local indexer_setting
                        local indexer_regex

                        debug "        ${type}"
                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            indexer_name="${indexer} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                            # Name, URL/Host, Verify SSL, API Key, Newznab UID, Enabled
                            indexer_setting="${indexer_name}, ${indexer_url}, 0, ${API_KEYS[${indexer}]}, , 1"
                            indexer_regex="${indexer_name}, http?://*/*, ?, *, *, [0,1],"
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            indexer_name="${indexer} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${indexer_base} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                            # Name, URL/Host, Verify SSL, Torznab Category, Enabled
                            indexer_setting="${indexer_name}, ${indexer_url}, ${API_KEYS[${indexer}]}, , 1"
                            indexer_regex="${indexer_name}, http?://*/*, ?, *, [0,1],"
                        else
                            fatal "        ${type} not supported and this shouldn't have happened..."
                        fi
                        implementation_lower=$(echo "${implementation}" | tr '[:upper:]' '[:lower:]')

                        indexers=$(crudini --get "${config_path}" "${implementation}" "extra_${implementation_lower}s")

                        if [[ ${indexers} == "" ]]; then
                            debug "        Adding first ${implementation}"
                            crudini --set "${config_path}" "${implementation}" "extra_${implementation_lower}s" "${indexer_setting}"
                        elif [[ ${indexers} == *"${indexer_name}"* ]]; then
                            debug "        Updating ${implementation}"
                            debug "        indexers=${indexers}"
                            indexers=${indexers//${indexer_regex}/${indexer_setting}}
                            debug "        indexers=${indexers}"
                            crudini --set "${config_path}" "${implementation}" "extra_${implementation_lower}s"
                        else
                            debug "        Adding additional ${implementation}"
                            crudini --set "${config_path}" "${implementation}" "extra_${implementation_lower}s" "${indexers}, ${indexer_setting}"
                        fi

                        # Enable to general indexer
                        if [[ ${type} == "usenet" ]]; then
                            crudini --set "${config_path}" "${implementation}" "${implementation_lower}" "true"
                        elif [[ ${type} == "torrent" ]]; then
                            crudini --set "${config_path}" "${implementation}" "enable_${implementation_lower}" "true"
                        fi

                        provider_order=$(crudini --get "${config_path}" "Providers" "provider_order")
                        debug "        Providers:${provider_order}"
                        if [[ ${provider_order} == "" || ${provider_order} == "0," ]]; then
                            debug "        Adding first provider to list"
                            crudini --set "${config_path}" "Providers" "provider_order" "0, ${indexer_name}"
                        elif [[ ${provider_order} == *"${indexer_name}"* ]]; then
                            debug "        Provider already exists in list"
                        else
                            debug "        Adding provider to list"
                            IFS="," read -ra provider_order_list <<< "${provider_order}"
                            for provider in "${provider_order_list[@]}"; do
                                local re='^[0-9]+$'
                                if [[ ${provider} =~ ${re} ]] ; then
                                    debug "          provider:${provider}"
                                    index=${provider}
                                fi
                            done
                            index=$((index + 1))
                            debug "          index:${index}"
                            provider_order="${provider_order}, ${index}, ${indexer_name}"
                            crudini --set "${config_path}" "Providers" "provider_order" "${provider_order}"
                            debug "        Providers:${provider_order}"
                        fi
                    done

                    if [[ ${indexer} == "hydra2" ]]; then
                        hydra2_configured="true"
                    fi

                    indexer_configured="true"
                fi
            fi
        fi
    done

    if [[ ${indexer_configured} != "true" ]]; then
        warning "      No Indexers to configure."
    fi
}

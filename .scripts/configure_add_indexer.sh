#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_indexer() {
    info "  - Updating Indexer settings"
    local container_name="${1}"
    local db_path="${2}"
    local indexer_configured="false"
    local hydra2_configured="false"
    debug "    container_name=${container_name}"
    debug "    db_path=${db_path}"
    # Define supported indexers and their default listening port
    typeset -A indexer_names
    typeset -A indexer_port
    indexer_names[0]="hydra2"
    indexer_names[1]="jackett"
    indexer_ports[0]="5076"
    indexer_ports[1]="9117"

    for index in "${!indexer_name[@]}"; do
        local indexer
        indexer=${indexer_names[$index]}
        # shellcheck disable=SC2154,SC2001
        if [[ ${containers[${indexer}]+true} == "true" ]]; then
            if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" || ${container_name} == "lidarr" ]]; then
                if [[ ${indexer} == "hydra2" || (${indexer} == "jackett" && ${hydra2_configured} != "true") ]]; then
                    info "    - Linking ${container_name} to ${indexer}..."
                    local indexer_db_id
                    local indexer_settings
                    local indexer_port
                    local indexer_base
                    local indexer_url
                    local categories
                    local additional_columns
                    local additional_values
                    indexer_base=$(jq -r '.base_url' <<< "${containers[${container_name}]}")
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
                    debug "      container_name=${container_name}"
                    debug "      categories=${categories}"

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
                        implementation="Newznab"
                        config_contract="NewznabSettings"
                        indexer_type=("torrent" "usenet")
                    elif [[ ${indexer} == "jackett" ]]; then
                        implementation="Torznab"
                        config_contract="TorznabSettings"
                        indexer_type=("torrent")
                    else
                        implementation="Newznab"
                        config_contract="NewznabSettings"
                        indexer_type=("torrent")
                    fi

                    for type in "${indexer_type[@]}"; do
                        local indexer_url
                        local indexer_name

                        if [[ ${type} == "usenet" ]]; then
                            indexer_name="${indexer} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                        elif [[ ${type} == "torrent" ]]; then
                            indexer_name="${indexer} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${indexer_url_base} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                        else
                            indexer_name="${indexer} (DSAC)"
                            indexer_url=${indexer_url_base}
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
                        debug "      Get ${indexer} DB ID"
                        indexer_db_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='${indexer_name}'")
                        debug "      ${indexer} DB ID: ${indexer_db_id}"
                        # Get settings for indexer
                        indexer_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$indexer_db_id")
                        # Set indexer API Key
                        debug "      Setting API Key to: ${API_KEYS[${indexer}]}"
                        indexer_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[${indexer}]}"'",/' <<< "$indexer_settings")
                        # Set indexer Url
                        debug "      Setting URL to: ${indexer_url}"
                        indexer_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${indexer_url}"'",#' <<< "$indexer_settings")
                        # Set categories
                        debug "      Setting categories to: [${categories}]"
                        indexer_settings=$(sed 's#"categories":.*,#"categories": ['"${categories}"'],#' <<< "$indexer_settings")
                        #Update the settings for indexer
                        debug "      Updating DB"
                        sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$indexer_settings' WHERE id=$indexer_db_id"
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
        warning "    No Indexers to configure."
    fi
}

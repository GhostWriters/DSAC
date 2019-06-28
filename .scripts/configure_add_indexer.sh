#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_indexer() {
    local container_name="${1}"
    local db_path="${2}"
    local indexer_configured="false"

    info "  - Updating Indexer settings"
    # shellcheck disable=SC2154,SC2001
    if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" || ${container_name} == "lidarr" ]]; then
        if [[ ${containers[hydra2]+true} == "true" ]]; then
            local hydra2_id
            local hydra2_settings
            local hydra2_port
            hydra2_port=${containers_ports[hydra2]}
            #TODO: Make this pull from configuration file or db
            local hydra2_base
            hydra2_base="/"
            local hydra2_url
            hydra2_url="http://${LOCAL_IP}:${hydra2_port}${hydra2_base}"
            local categories
            local additional_columns
            local additional_values

            debug "    container_name=${container_name}"
            debug "    db_path=${db_path}"

            info "    Hydra2"
            debug "    Adding NZBHydra2 as an indexer, if needed..."

            if [[ ${container_name} == "radarr" ]]; then
                categories="2000,2010,2020,2030,2035,2040,2045,2050,2060"
            elif [[ ${container_name} == "sonarr" ]]; then
                categories="5030,5040"
            elif [[ ${container_name} == "lidarr" ]]; then
                categories="3000,3010,3020,3030,3040"
            else
                categories=""
                warning "    No categories configured for ${container_name}"
            fi
            debug "    container_name=${container_name}"
            debug "    categories=${categories}"

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

            #NZB Indexer
            local hydra2_url_newznab
            hydra2_url_newznab=${hydra2_url}
            sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss${additional_columns})
                                    SELECT 'NZBHydra2 - Usenet (DSAC)','Newznab','{
                                            \"baseUrl\": \"${hydra2_url_newznab}\",
                                            \"multiLanguages\": [],
                                            \"apiKey\": \"${API_KEYS[hydra2]}\",
                                            \"categories\": [${categories}],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','NewznabSettings',1${additional_values}
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 - Usenet (DSAC)');"
            debug "    Get Hydra ID"
            hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 - Usenet (DSAC)'")
            debug "    Hydra DB ID: ${hydra2_id}"
            # Get settings for Hydra
            hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[hydra2]}"'",/' <<< "$hydra2_settings")
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url_newznab}"
            hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${hydra2_url_newznab}"'",#' <<< "$hydra2_settings")
            # Set categories
            debug "    Setting categories to: [${categories}]"
            hydra2_settings=$(sed 's#"categories":.*,#"categories": ['"${categories}"'],#' <<< "$hydra2_settings")
            debug "    hydra2_settings=${hydra2_settings}"
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$hydra2_settings' WHERE id=$hydra2_id"

            #Torrent Indexer
            local hydra2_url_torznab
            if [[ ${hydra2_base} == "/" ]]; then
                hydra2_url_torznab="${hydra2_url}torznab"
            else
                hydra2_url_torznab="${hydra2_url}/torznab"
            fi
            sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss${additional_columns})
                                    SELECT 'NZBHydra2 - Torrents (DSAC)','Torznab','{
                                            \"baseUrl\": \"${hydra2_url_torznab}\",
                                            \"multiLanguages\": [],
                                            \"apiKey\": \"${API_KEYS[hydra2]}\",
                                            \"categories\": [${categories}],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','TorznabSettings',1${additional_values}
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 - Torrents (DSAC)');"
            debug "    Get Hydra ID"
            hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 - Torrents (DSAC)'")
            debug "    Hydra DB ID: ${hydra2_id}"
            # Get settings for Hydra
            hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[hydra2]}"'",/' <<< "$hydra2_settings")
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url_torznab}"
            hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${hydra2_url_torznab}"'",#' <<< "$hydra2_settings")
            # Set categories
            debug "    Setting categories to: [${categories}]"
            hydra2_settings=$(sed 's#"categories":.*,#"categories": ['"${categories}"'],#' <<< "$hydra2_settings")
            debug "    hydra2_settings=${hydra2_settings}"
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$hydra2_settings' WHERE id=$hydra2_id"
            indexer_configured="true"
        elif [[ ${containers[jackett]+true} == "true" ]]; then
            indexer_configured="false"
        fi
    fi

    if [[ ${container_name} == "hydra2" ]]; then
        if [[ ${containers[jackett]+true} == "true" ]]; then
            indexer_configured="false"
        fi
    fi

    if [[ ${indexer_configured} != "true" ]]; then
        warning "    No Indexers to configure."
    fi
}

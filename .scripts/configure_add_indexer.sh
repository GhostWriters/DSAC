#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_indexer() {
    local container_name="${1}"
    local db_path="${2}"
    local indexer_configured="false"

    info "  - Updating Indexer settings"
    if [[ ${containers[hydra2]+true} == "true" ]]; then
        if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" ]]; then
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

            info "    Hydra2"
            debug "    Adding NZBHydra2 as an indexer, if needed..."

            if [[ ${container_name} == "radarr" ]]; then
                categories="2000,2010,2020,2030,2035,2040,2045,2050,2060"
            elif [[ ${container_name} == "sonarr" ]]; then
                categories="5030,5040"
            else
                categories=""
                warning "    No categories configured for ${container_name}"
            fi

            sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss,EnableSearch)
                                    SELECT 'NZBHydra2 (DSAC)','Newznab','{
                                            \"baseUrl\": \"${hydra2_url}\",
                                            \"multiLanguages\": [],
                                            \"apiKey\": \"${API_KEYS[hydra2]}\",
                                            \"categories\": [${categories}],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','NewznabSettings',1,1
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 (DSAC)');"
            debug "    Get Hydra ID"
            hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 (DSAC)'")
            debug "    Hydra DB ID: ${hydra2_id}"
            # Get settings for Hydra
            hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[hydra2]}"'",/' <<< "$hydra2_settings")
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url}"
            hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${hydra2_url}"'",#' <<< "$hydra2_settings")
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$hydra2_settings' WHERE id=$hydra2_id"
            indexer_configured="true"
        fi
    fi

    if [[ ${indexer_configured} != "true" ]]; then
        warning "    No Indexers to configure."
    fi
}

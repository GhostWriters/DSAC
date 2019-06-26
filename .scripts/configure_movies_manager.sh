#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_movies_manager() {
    info "Configuring Movie Manager(s)"
    local container_name="radarr"
    local config_file="config.xml"
    # shellcheck disable=SC2154
    local config_path="${containers_config_path[$container_name]}/${config_file}"
    local db_file="nzbdrone.db"
    # shellcheck disable=SC2154
    local db_path="${containers_config_path[$container_name]}/${db_file}"
    local indexer_configured="false"

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- Radarr"
        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        debug "    db_path=${db_path}"
        cp "${db_path}" "${db_path}.dsac_bak"
        info "  - Updating Indexer settings"
        if [[ ${containers[hydra2]+true} == "true" ]]; then
            local radarr_hydra2_id
            local radarr_hydra2_settings
            local hydra2_port
            hydra2_port=${containers_ports[hydra2]} #TODO: Make this pull from configuration file or db
            local hydra2_base
            hydra2_base="/" #TODO: Make this pull from configuration file or db
            local hydra2_url
            hydra2_url="http://${LOCAL_IP}:${hydra2_port}${hydra2_base}"

            info "    Hydra2"
            debug "    Adding NZBHydra2 as an indexer, if needed..."
            sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss,EnableSearch)
                                    SELECT 'NZBHydra2 (DSAC)','Newznab','{
                                            \"baseUrl\": \"${hydra2_url}\",
                                            \"multiLanguages\": [],
                                            \"apiKey\": \"${API_KEYS[hydra2]}\",
                                            \"categories\": [2000,2010,2020,2030,2035,2040,2045,2050,2060],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','NewznabSettings',1,1
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 (DSAC)');"
            debug "    Get Hydra ID"
            radarr_hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 (DSAC)'")
            debug "    Hydra DB ID: ${radarr_hydra2_id}"
            # Get settings for Hydra
            radarr_hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$radarr_hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            radarr_hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[hydra2]}"'",/' <<< "$radarr_hydra2_settings")
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url}"
            radarr_hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${hydra2_url}"'",#' <<< "$radarr_hydra2_settings")
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$radarr_hydra2_settings' WHERE id=$radarr_hydra2_id"
            indexer_configured="true"
        fi

        if [[ ${indexer_configured} != "true" ]]; then
            warning "    No Indexers to configure."
        fi

        run_script "configure_add_downloader" "$container_name" "${db_path}"
    fi
}

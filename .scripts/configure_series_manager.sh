#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_series_manager() {
    info "Configuring Series Manager(s)"
    local container_name="sonarr"
    local config_file="config.xml"
    local config_path="${containers_config_path[$container_name]}/${config_file}"
    local db_file="nzbdrone.db"
    local db_path="${containers_config_path[$container_name]}/${db_file}"
    local indexer_configured="false"
    local downloader_configured="false"

    if [[ ${containers[$container_name]+true} == "true" ]]; then
        info "- Sonarr"
        info "  - Backing up the config file: ${config_file} >> ${config_file}.dsac_bak"
        debug "    config_path=${config_path}"
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        debug "    db_path=${db_path}"
        cp "${db_path}" "${db_path}.dsac_bak"
        info "  - Updating Indexer settings"
        if [[ ${containers[hydra2]+true} == "true" ]]; then
            local sonarr_hydra2_id
            local sonarr_hydra2_settings
            local hydra2_port=${containers_ports[hydra2]} #TODO: Make this pull from configuration file or db
            local hydra2_base="/" #TODO: Make this pull from configuration file or db
            local hydra2_url="http://${LOCAL_IP}:${hydra2_port}${hydra2_base}"

            info "    Hydra2"
            debug "    Adding NZBHydra2 as an indexer, if needed..."
            $(sqlite3 "${db_path}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss,EnableSearch)
                                    SELECT 'NZBHydra2 (DSAC)','Newznab','{
                                            \"baseUrl\": \"${hydra2_url}\",
                                            \"multiLanguages\": [],
                                            \"apiKey\": \"${API_KEYS[hydra2]}\",
                                            \"categories\": [5030,5040],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','NewznabSettings',1,1
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 (DSAC)');")
            debug "    Get Hydra ID"
            sonarr_hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 (DSAC)'")
            debug "    Hydra DB ID: ${sonarr_hydra2_id}"
            # Get settings for Hydra
            sonarr_hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$sonarr_hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            sonarr_hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'${API_KEYS[hydra2]}'",/' <<< $sonarr_hydra2_settings)
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url}"
            sonarr_hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'${hydra2_url}'",#' <<< $sonarr_hydra2_settings)
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$sonarr_hydra2_settings' WHERE id=$sonarr_hydra2_id"
            indexer_configured="true"
        fi

        if [[ "${indexer_configured}" != "true" ]]; then
            warning "    None to configure."
        fi

        run_script "configure_add_downloader" "$container_name" "${db_path}"

        if [[ "${downloader_configured}" != "true" ]]; then
            warning "    None to configure."
        fi
    fi
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_movies_manager() {
    info "Configuring Movie Manager(s)"
    local container_name="radarr"
    local config_file="config.xml"
    local config_path="${containers_config_path[$container_name]}/${config_file}"
    local db_file="nzbdrone.db"
    local db_path="${containers_config_path[$container_name]}/${db_file}"
    local indexer_configured="false"
    local downloader_configured="false"

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
                                            \"categories\": [2000,2010,2020,2030,2035,2040,2045,2050,2060],
                                            \"animeCategories\": [],
                                            \"removeYear\": false,
                                            \"searchByTitle\": false }','NewznabSettings',1,1
                                    WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='NZBHydra2 (DSAC)');")
            debug "    Get Hydra ID"
            radarr_hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='NZBHydra2 (DSAC)'")
            debug "    Hydra DB ID: ${radarr_hydra2_id}"
            # Get settings for Hydra
            radarr_hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$radarr_hydra2_id")
            # Set Hydra2 API Key
            debug "    Setting API Key to: ${API_KEYS[hydra2]}"
            radarr_hydra2_settings=$(sed 's/"apiKey":.*",/"apiKey": "'${API_KEYS[hydra2]}'",/' <<< $radarr_hydra2_settings)
            # Set Hydra2 Url
            debug "    Setting URL to: ${hydra2_url}"
            radarr_hydra2_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'${hydra2_url}'",#' <<< $radarr_hydra2_settings)
            #Update the settings for Hydra
            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$radarr_hydra2_settings' WHERE id=$radarr_hydra2_id"
            indexer_configured="true"
        fi

        if [[ "${indexer_configured}" != "true" ]]; then
            warning "    None to configure."
        fi

        info "  - Updating Downloader settings"
        if [[ ${containers[nzbget]+true} == "true" ]]; then
            local radarr_nzbget_id
            local radarr_nzbget_settings
            local radarr_port=${containers_ports[nzbget]} #TODO: Make this pull from configuration file or db
            info "    NZBget"
            debug "    Adding NZBget as an downloader, if needed..."
            $(sqlite3 "${db_path}" "INSERT INTO DownloadClients (Enable,Name,Implementation,Settings,ConfigContract)
                                    SELECT 1, 'NZBget (DSAC)','Nzbget','{
                                            \"host\": \"${LOCAL_IP}\",
                                            \"port\": ${radarr_port},
                                            \"username\": \"nzbget\",
                                            \"password\": \"tegbzn6789\",
                                            \"movieCategory\": \"Movies\",
                                            \"recentMoviePriority\": 0,
                                            \"olderMoviePriority\": 0,
                                            \"useSsl\": false,
                                            \"addPaused\": false
                                            }','NzbgetSettings'
                                    WHERE NOT EXISTS(SELECT 1 FROM DownloadClients WHERE name='NZBget (DSAC)');")
            debug "    Get NZBget ID"
            radarr_nzbget_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='NZBget (DSAC)'")
            debug "    NZBget DB ID: ${radarr_nzbget_id}"
            radarr_nzbget_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$radarr_nzbget_id")
            # Set host
            debug "Setting host to: ${LOCAL_IP}"
            radarr_nzbget_settings=$(sed 's/"host":.*/"host": "'${LOCAL_IP}'",/' <<< $radarr_nzbget_settings)
            # Set port
            debug "Setting host to: ${radarr_port}"
            radarr_nzbget_settings=$(sed 's/"port":.*/"port": "'${radarr_port}'",/' <<< $radarr_nzbget_settings)
            # Set username
            debug "Setting username to: nzbget"
            radarr_nzbget_settings=$(sed 's/"username":.*/"username": "nzbget",/' <<< $radarr_nzbget_settings)
            # Set password
            debug "Setting password to: tegbzn6789"
            radarr_nzbget_settings=$(sed 's/"password":.*/"password": "tegbzn6789",/' <<< $radarr_nzbget_settings)
            # Change movieCategory to lowercase
            debug "Setting movieCategory to: Movies"
            radarr_nzbget_settings=$(sed 's/"movieCategory":.*/"movieCategory": "Movies",/' <<< $radarr_nzbget_settings)
            debug "Updating DB"
            sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$radarr_nzbget_settings' WHERE id=$radarr_nzbget_id"
            downloader_configured="true"
        fi

        if [[ "${downloader_configured}" != "true" ]]; then
            warning "    None to configure."
        fi
    fi
}

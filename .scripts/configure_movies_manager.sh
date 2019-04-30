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
        cp "${config_path}" "${config_path}.dsac_bak"
        info "  - Backing up the database: ${db_file} >> ${db_file}.dsac_bak"
        cp "${db_path}" "${db_path}.dsac_bak"
        info "  - Updating Indexer settings"
        if [[ ${containers[hydra2]+true} == "true" ]]; then
            info "    Hydra2"
            local radarr_hydra2_id
            radarr_hydra2_id=$(sqlite3 "${db_path}" "SELECT id FROM Indexers WHERE Name='Hydra'")
            local radarr_hydra2_settings
            radarr_hydra2_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM Indexers WHERE id=$radarr_hydra2_id")
            # Set Hydra2 API Key
            debug "Setting API Key to: ${API_KEYS[hydra2]}"
            radarr_hydra2_settings=$(sed 's/"apiKey":.*/"apiKey": "'${API_KEYS[hydra2]}'",/' <<< $radarr_hydra2_settings)
            # Set Hydra2 baseUrl
            # TODO: hydra2_baseurl=
            debug "Setting Base URL to: http://localhost:5075/hydra2"
            radarr_hydra2_settings=$(sed 's#"baseUrl":.*#"baseUrl": "http://localhost:5075/hydra2",#' <<< $radarr_hydra2_settings)
            debug "Updating DB"
            sqlite3 "${db_path}" "UPDATE Indexers SET Settings='$radarr_hydra2_settings' WHERE id=$radarr_hydra2_id"
            indexer_configured="true"
        fi

        if [[ "${indexer_configured}" != "true" ]]; then
            warning "    None to configure."
        fi

        info "  - Updating Downloader settings"
        if [[ ${containers[nzbget]+true} == "true" ]]; then
            info "    NZBget"
            local radarr_nzbget_id
            radarr_nzbget_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='NZBget'")
            local radarr_nzbget_settings
            radarr_nzbget_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$radarr_nzbget_id")
            # Change movieCategory to lowercase
            debug "Setting movieCategory to: movies"
            radarr_nzbget_settings=$(sed 's/"movieCategory":.*/"movieCategory": "movies",/' <<< $radarr_nzbget_settings)
            debug "Updating DB"
            sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$radarr_nzbget_settings' WHERE id=$radarr_nzbget_id"
            downloader_configured="true"
        fi

        if [[ ${containers[sabnzb]+true} == "true" ]]; then
            info "    SABnzb"
            local radarr_sabnzb_id
            radarr_sabnzb_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='SABnzbd'")
            local radarr_sabnzb_settings
            radarr_sabnzb_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$radarr_sabnzb_id")
            # Set SABnzb API Key
            debug "Setting API Key to: ${API_KEYS[sabnzbd]}"
            radarr_sabnzb_settings=$(sed 's/"apiKey":.*/"apiKey": "'${API_KEYS[sabnzbd]}'",/' <<< $radarr_sabnzb_settings)
            debug "Updating DB"
            sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$radarr_sabnzb_settings' WHERE id=$radarr_sabnzb_id"
            downloader_configured="true"
        fi

        if [[ "${downloader_configured}" != "true" ]]; then
            warning "    None to configure."
        fi
    fi
}

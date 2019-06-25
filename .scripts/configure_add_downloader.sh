#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_downloader() {
    local container_name="${1}"
    local db_path="${2}"
    local downloader_configured="false"

    info "  - Updating Downloader settings"
    if [[ ${containers[nzbget]+true} == "true" ]]; then
        local nzbget_id
        local nzbget_settings
        local port=${containers_ports[nzbget]} #TODO: Make this pull from configuration file or db
        info "    NZBget"
        debug "    Adding NZBget as an downloader, if needed..."
        $(sqlite3 "${db_path}" "INSERT INTO DownloadClients (Enable,Name,Implementation,Settings,ConfigContract)
                                SELECT 1, 'NZBget (DSAC)','Nzbget','{
                                        \"host\": \"${LOCAL_IP}\",
                                        \"port\": ${port},
                                        \"username\": \"nzbget\",
                                        \"password\": \"tegbzn6789\",
                                        \"movieCategory\": \"Movies\",
                                        \"TvCategory\": \"Series\",
                                        \"recentMoviePriority\": 0,
                                        \"recentTvPriority\": 0,
                                        \"olderMoviePriority\": 0,
                                        \"olderTvPriority\": 0,
                                        \"useSsl\": false,
                                        \"addPaused\": false
                                        }','NzbgetSettings'
                                WHERE NOT EXISTS(SELECT 1 FROM DownloadClients WHERE name='NZBget (DSAC)');")
        debug "    Get NZBget ID"
        nzbget_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='NZBget (DSAC)'")
        debug "    NZBget DB ID: ${nzbget_id}"
        nzbget_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$nzbget_id")
        # Set host
        debug "Setting host to: ${LOCAL_IP}"
        nzbget_settings=$(sed 's/"host":.*/"host": "'${LOCAL_IP}'",/' <<< $nzbget_settings)
        # Set port
        debug "Setting host to: ${port}"
        nzbget_settings=$(sed 's/"port":.*/"port": "'${port}'",/' <<< $nzbget_settings)
        # Set username
        debug "Setting username to: nzbget"
        nzbget_settings=$(sed 's/"username":.*/"username": "nzbget",/' <<< $nzbget_settings)
        # Set password
        debug "Setting password to: tegbzn6789"
        nzbget_settings=$(sed 's/"password":.*/"password": "tegbzn6789",/' <<< $nzbget_settings)
        # Change TvCategory
        debug "Setting TvCategory to: Series"
        nzbget_settings=$(sed 's/"TvCategory":.*/"TvCategory": "Series",/' <<< $nzbget_settings)
        # Set movieCategory
        debug "Setting movieCategory to: Movies"
        nzbget_settings=$(sed 's/"movieCategory":.*/"movieCategory": "Movies",/' <<< $nzbget_settings)
        debug "Updating DB"
        sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$nzbget_settings' WHERE id=$nzbget_id"
        downloader_configured="true"
    fi

    if [[ "${downloader_configured}" != "true" ]]; then
        warning "    None to configure."
    fi
}

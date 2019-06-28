#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_downloader() {
    local container_name="${1}"
    local db_path="${2}"
    local downloader_configured="false"

    info "  - Updating Downloader settings"
    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[nzbget]+true} == "true" ]]; then
        if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" ]]; then
            local nzbget_id
            local nzbget_settings
            local nzbget_restricted_username
            nzbget_restricted_username=${API_KEYS[nzbget]%%,*}
            local nzbget_restricted_password
            nzbget_restricted_password=${API_KEYS[nzbget]#*,}
            local port
            port=${containers_ports[nzbget]} #TODO: Make this pull from configuration file or db

            debug "    container_name=${container_name}"
            debug "    db_path=${db_path}"
            debug "    nzbget_restricted_username='${nzbget_restricted_username}'"
            debug "    nzbget_restricted_password='${nzbget_restricted_password}'"

            info "    NZBget"
            debug "    Adding NZBget as an downloader, if needed..."
            sqlite3 "${db_path}" "INSERT INTO DownloadClients (Enable,Name,Implementation,Settings,ConfigContract)
                                    SELECT 1, 'NZBget (DSAC)','Nzbget','{
                                            \"host\": \"${LOCAL_IP}\",
                                            \"port\": ${port},
                                            \"username\": \"${nzbget_restricted_username}\",
                                            \"password\": \"${nzbget_restricted_password}\",
                                            \"movieCategory\": \"Movies\",
                                            \"TvCategory\": \"Series\",
                                            \"musicCategory\": \"Music\",
                                            \"recentMoviePriority\": 0,
                                            \"olderMoviePriority\": 0,
                                            \"recentTvPriority\": 0,
                                            \"olderTvPriority\": 0,
                                            \"recentMusicPriority\": 0,
                                            \"olderMusicPriority\": 0,
                                            \"useSsl\": false,
                                            \"addPaused\": false
                                            }','NzbgetSettings'
                                    WHERE NOT EXISTS(SELECT 1 FROM DownloadClients WHERE name='NZBget (DSAC)');"
            debug "    Get NZBget ID"
            nzbget_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='NZBget (DSAC)'")
            debug "    NZBget DB ID: ${nzbget_id}"
            nzbget_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$nzbget_id")
            # Set host
            debug "    Setting host to: ${LOCAL_IP}"
            nzbget_settings=$(sed 's/"host":.*/"host": "'"${LOCAL_IP}"'",/' <<< "$nzbget_settings")
            # Set port
            debug "    Setting port to: ${port}"
            nzbget_settings=$(sed 's/"port":.*/"port": "'"${port}"'",/' <<< "$nzbget_settings")
            # Set username
            debug "    Setting username to: ${nzbget_restricted_username}"
            nzbget_settings=$(sed 's/"username":.*/"username": "'"${nzbget_restricted_username}"'",/' <<< "$nzbget_settings")
            # Set password
            debug "    Setting password to: ${nzbget_restricted_password}"
            nzbget_settings=$(sed 's/"password":.*/"password": "'"${nzbget_restricted_password}"'",/' <<< "$nzbget_settings")

            if [[ ${container_name} == "sonarr" ]]; then
                # Change TvCategory
                debug "    Setting TvCategory to: Series"
                nzbget_settings=$(sed 's/"TvCategory":.*/"TvCategory": "Series",/' <<< "$nzbget_settings")
            elif [[ ${container_name} == "radarr" ]]; then
                # Set movieCategory
                debug "    Setting movieCategory to: Movies"
                nzbget_settings=$(sed 's/"movieCategory":.*/"movieCategory": "Movies",/' <<< "$nzbget_settings")
            elif [[ ${container_name} == "lidarr" ]]; then
                # Set musicCategory
                debug "    Setting musicCategory to: Music"
                nzbget_settings=$(sed 's/"musicCategory":.*/"musicCategory": "Music",/' <<< "$nzbget_settings")
            fi

            debug "    Updating DB"
            sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$nzbget_settings' WHERE id=$nzbget_id"
            downloader_configured="true"
        fi
    fi

    if [[ ${downloader_configured} != "true" ]]; then
        warning "    No Downloaders to configure."
    fi
}

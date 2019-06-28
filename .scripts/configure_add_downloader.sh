#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_downloader() {
    local container_name="${1}"
    local db_path="${2}"
    local downloader_configured="false"

    info "  - Updating Downloader settings"
    # shellcheck disable=SC2154,SC2001
    if [[ ${container_name} == "radarr" || ${container_name} == "sonarr" ]]; then
        # Define supported downloaders and their default listening port
        typeset -A downloaders
        downloaders[nzbget]="6789"
        downloaders[qbittorrent]="8080"

        for downloader in "${!downloaders[@]}"; do
            local db_id
            local db_name
            local db_implementation
            local db_config_contract
            local db_settings
            local port
            local db_settings_new
            debug "    container_name=${container_name}"
            debug "    db_path=${db_path}"

            if [[ ${containers[${downloader}]+true} == "true" ]]; then
                if [[ "${downloader}" == "nzbget" ]]; then
                    info "    - Linking ${container_name} to ${downloader}..."
                    local nzbget_restricted_username
                    local nzbget_restricted_password
                    db_name="${downloader} (DSAC)"
                    db_implementation="Nzbget"
                    db_config_contract="NzbgetSettings"
                    nzbget_restricted_username=${API_KEYS[nzbget]%%,*}
                    nzbget_restricted_password=${API_KEYS[nzbget]#*,}
                    port=$(jq -r --arg port ${downloaders[${downloader}]} '.ports[$port]' <<< "${containers[${downloader}]}")
                    db_settings_new="{
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
                                    }"
                elif [[ "${downloader}" == "qbittorrent" ]]; then
                    db_name="${downloader} (DSAC)"
                    db_implementation="QBittorrent"
                    db_config_contract="QBittorrentSettings"
                    db_settings_new="{
                                        \"host\": \"${LOCAL_IP}\",
                                        \"port\": ${port},
                                        \"movieCategory\": \"Movies\",
                                        \"TvCategory\": \"Series\",
                                        \"musicCategory\": \"Music\",
                                        \"recentMoviePriority\": 0,
                                        \"olderMoviePriority\": 0,
                                        \"recentTvPriority\": 0,
                                        \"olderTvPriority\": 0,
                                        \"recentMusicPriority\": 0,
                                        \"olderMusicPriority\": 0,
                                        \"initialState\": 0,
                                        \"useSsl\": false,
                                    }"
                fi

                debug "      Adding ${downloader} as an downloader, if needed..."
                sqlite3 "${db_path}" "INSERT INTO DownloadClients (Enable,Name,Implementation,Settings,ConfigContract)
                                        SELECT 1, '${db_name}','${db_implementation}','${db_settings_new}','${db_config_contract}'
                                        WHERE NOT EXISTS(SELECT 1 FROM DownloadClients WHERE name='${db_name}');"
                debug "      Get ${downloader} DB ID"
                db_id=$(sqlite3 "${db_path}" "SELECT id FROM DownloadClients WHERE Name='${db_name}'")
                debug "      NZBget DB ID: ${db_id}"
                db_settings=$(sqlite3 "${db_path}" "SELECT Settings FROM DownloadClients WHERE id=$db_id")
                # Set host
                debug "      Setting host to: ${LOCAL_IP}"
                db_settings=$(sed 's/"host":.*/"host": "'"${LOCAL_IP}"'",/' <<< "$db_settings")
                # Set port
                debug "      Setting port to: ${port}"
                db_settings=$(sed 's/"port":.*/"port": "'"${port}"'",/' <<< "$db_settings")

                if [[ "${downloader}" == "nzbget" ]]; then
                    # Set username
                    debug "      Setting username to: ${nzbget_restricted_username}"
                    db_settings=$(sed 's/"username":.*/"username": "'"${nzbget_restricted_username}"'",/' <<< "$db_settings")
                    # Set password
                    debug "      Setting password to: ${nzbget_restricted_password}"
                    db_settings=$(sed 's/"password":.*/"password": "'"${nzbget_restricted_password}"'",/' <<< "$db_settings")
                fi

                if [[ ${container_name} == "sonarr" ]]; then
                    # Change TvCategory
                    debug "      Setting TvCategory to: Series"
                    db_settings=$(sed 's/"TvCategory":.*/"TvCategory": "Series",/' <<< "$db_settings")
                elif [[ ${container_name} == "radarr" ]]; then
                    # Set movieCategory
                    debug "      Setting movieCategory to: Movies"
                    db_settings=$(sed 's/"movieCategory":.*/"movieCategory": "Movies",/' <<< "$db_settings")
                elif [[ ${container_name} == "lidarr" ]]; then
                    # Set musicCategory
                    debug "      Setting musicCategory to: Music"
                    db_settings=$(sed 's/"musicCategory":.*/"musicCategory": "Music",/' <<< "$db_settings")
                fi

                debug "      Updating DB"
                sqlite3 "${db_path}" "UPDATE DownloadClients SET Settings='$db_settings' WHERE id=$db_id"
                downloader_configured="true"
            fi
        done
    fi

    if [[ ${downloader_configured} != "true" ]]; then
        warning "    No Downloaders to configure."
    fi
}

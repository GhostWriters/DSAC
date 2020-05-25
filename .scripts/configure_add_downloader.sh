#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_downloader() {
    local CONTAINER_NAME="${1}"
    local DB_PATH="${2}"
    local CONFIG_PATH="${3}"
    local DOWNLOADER_CONFIGURED="false"
    local LOCAL_IP
    LOCAL_IP=$(run_script 'detect_local_ip')
    # Get supported DOWNLOADERS
    mapfile -t DOWNLOADERS < <(yq-go r "${DETECTED_DSACDIR}/.data/supported_apps.yml" "DOWNLOADERS.*" | awk '{gsub("- ",""); print}')
    info "Updating Downloader settings"
    debug "CONTAINER_NAME=${CONTAINER_NAME}"
    debug "DB_PATH=${DB_PATH}"

    for DOWNLOADER in "${!DOWNLOADERS[@]}"; do
        local DOWNLOADER_YML
        DOWNLOADER_YML="services.${DOWNLOADER}.labels[com.dockstarter.dsac]"
        local DOWNLOADER_YML_FILE
        DOWNLOADER_YML_FILE="${DETECTED_DSACDIR}/.data/apps/${DOWNLOADER}/${DOWNLOADER}.yml"
        local PORT
        PORT=$(yq-go r "${DOWNLOADER_YML_FILE}" "${DOWNLOADER_YML}.ports.default")
        PORT=$(yq-go r "${DOWNLOADER_YML_FILE}" "${DOWNLOADER_YML}.ports.${PORT}" || echo "${PORT}")
        # shellcheck disable=SC2154,SC2001
        if [[ ${CONTAINER_NAME} == "radarr" || ${CONTAINER_NAME} == "sonarr" || ${CONTAINER_NAME} == "lidarr" ]]; then
            local DB_ID
            local DB_NAME
            local DB_IMPLEMENTATION
            local DB_CONFIG_CONTRACT
            local DB_SETTINGS
            local DB_SETTINGS_NEW

            if [[ -f ${DOWNLOADER_YML_FILE} ]]; then
                if [[ ${DOWNLOADER} == "nzbget" ]]; then
                    info "Linking ${CONTAINER_NAME} to ${DOWNLOADER}..."
                    local NZBGET_RESTRICTED_USERNAME
                    local NZBGET_RESTRICTED_PASSWORD
                    DB_NAME="${DOWNLOADER} (DSAC)"
                    DB_IMPLEMENTATION="Nzbget"
                    DB_CONFIG_CONTRACT="NzbgetSettings"
                    NZBGET_RESTRICTED_USERNAME=${API_KEYS[${DOWNLOADER}]%%,*}
                    NZBGET_RESTRICTED_PASSWORD=${API_KEYS[${DOWNLOADER}]#*,}
                    DB_SETTINGS_NEW="{
                                        \"host\": \"${LOCAL_IP}\",
                                        \"PORT\": ${PORT},
                                        \"username\": \"${NZBGET_RESTRICTED_USERNAME}\",
                                        \"password\": \"${NZBGET_RESTRICTED_PASSWORD}\",
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
                elif [[ ${DOWNLOADER} == "qbittorrent" ]]; then
                    info "Linking ${CONTAINER_NAME} to ${DOWNLOADER}..."
                    DB_NAME="${DOWNLOADER} (DSAC)"
                    DB_IMPLEMENTATION="QBittorrent"
                    DB_CONFIG_CONTRACT="QBittorrentSettings"
                    DB_SETTINGS_NEW="{
                                        \"host\": \"${LOCAL_IP}\",
                                        \"PORT\": ${PORT},
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
                elif [[ ${DOWNLOADER} == "transmission" ]]; then
                    info "Linking ${CONTAINER_NAME} to ${DOWNLOADER}..."
                    DB_NAME="${DOWNLOADER} (DSAC)"
                    DB_IMPLEMENTATION="Transmission"
                    DB_CONFIG_CONTRACT="TransmissionSettings"
                    DB_SETTINGS_NEW="{
                                        \"host\": \"${LOCAL_IP}\",
                                        \"PORT\": ${PORT},
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

                debug "Adding ${DOWNLOADER} as an DOWNLOADER, if needed..."
                sqlite3 "${DB_PATH}" "INSERT INTO DownloadClients (Enable,Name,Implementation,Settings,ConfigContract)
                                        SELECT 1, '${DB_NAME}','${DB_IMPLEMENTATION}','${DB_SETTINGS_NEW}','${DB_CONFIG_CONTRACT}'
                                        WHERE NOT EXISTS(SELECT 1 FROM DownloadClients WHERE name='${DB_NAME}');"
                debug "Get ${DOWNLOADER} DB ID"
                DB_ID=$(sqlite3 "${DB_PATH}" "SELECT id FROM DownloadClients WHERE Name='${DB_NAME}'")
                debug "        ${DOWNLOADER} DB ID: ${DB_ID}"
                DB_SETTINGS=$(sqlite3 "${DB_PATH}" "SELECT Settings FROM DownloadClients WHERE id=$DB_ID")
                # Set host
                debug "Setting host to: ${LOCAL_IP}"
                DB_SETTINGS=$(sed 's/"host":.*/"host": "'"${LOCAL_IP}"'",/' <<< "$DB_SETTINGS")
                # Set PORT
                debug "Setting PORT to: ${PORT}"
                DB_SETTINGS=$(sed 's/"PORT":.*/"PORT": "'"${PORT}"'",/' <<< "$DB_SETTINGS")

                if [[ ${DOWNLOADER} == "nzbget" ]]; then
                    # Set username
                    debug "Setting username to: ${NZBGET_RESTRICTED_USERNAME}"
                    DB_SETTINGS=$(sed 's/"username":.*/"username": "'"${NZBGET_RESTRICTED_USERNAME}"'",/' <<< "$DB_SETTINGS")
                    # Set password
                    debug "Setting password to: ${NZBGET_RESTRICTED_PASSWORD}"
                    DB_SETTINGS=$(sed 's/"password":.*/"password": "'"${NZBGET_RESTRICTED_PASSWORD}"'",/' <<< "$DB_SETTINGS")
                fi

                if [[ ${CONTAINER_NAME} == "sonarr" ]]; then
                    # Change TvCategory
                    debug "Setting TvCategory to: Series"
                    DB_SETTINGS=$(sed 's/"TvCategory":.*/"TvCategory": "Series",/' <<< "$DB_SETTINGS")
                elif [[ ${CONTAINER_NAME} == "radarr" ]]; then
                    # Set movieCategory
                    debug "Setting movieCategory to: Movies"
                    DB_SETTINGS=$(sed 's/"movieCategory":.*/"movieCategory": "Movies",/' <<< "$DB_SETTINGS")
                elif [[ ${CONTAINER_NAME} == "lidarr" ]]; then
                    # Set musicCategory
                    debug "Setting musicCategory to: Music"
                    DB_SETTINGS=$(sed 's/"musicCategory":.*/"musicCategory": "Music",/' <<< "$DB_SETTINGS")
                fi

                debug "Updating DB"
                sqlite3 "${DB_PATH}" "UPDATE DownloadClients SET Settings='$DB_SETTINGS' WHERE id=$DB_ID"
                DOWNLOADER_CONFIGURED="true"
            fi
        fi

        if [[ ${CONTAINER_NAME} == "lazylibrarian" ]]; then
            local downloader_section

            if [[ ${containers[${DOWNLOADER}]+true} == "true" ]]; then

                if [[ ${DOWNLOADER} == "nzbget" ]]; then
                    info "Linking ${CONTAINER_NAME} to ${DOWNLOADER}..."
                    local NZBGET_RESTRICTED_USERNAME
                    local NZBGET_RESTRICTED_PASSWORD
                    NZBGET_RESTRICTED_USERNAME=${API_KEYS[nzbget]%%,*}
                    NZBGET_RESTRICTED_PASSWORD=${API_KEYS[nzbget]#*,}
                    downloader_section="NZBGet"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_port "${PORT}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_priority 0
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_category Books
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_user "${NZBGET_RESTRICTED_USERNAME}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_pass "${NZBGET_RESTRICTED_PASSWORD}"
                    crudini --set "${CONFIG_PATH}" USENET nzb_downloader_nzbget 1
                    DOWNLOADER_CONFIGURED="true"
                elif [[ ${DOWNLOADER} == "qbittorrent" ]]; then
                    downloader_section="QBITTORRENT"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_port "${PORT}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_base
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_dir
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_label Books
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_user
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_pass
                    crudini --set "${CONFIG_PATH}" TORRENT tor_downloader_qbittorrent 1
                    DOWNLOADER_CONFIGURED="true"
                elif [[ ${DOWNLOADER} == "transmission" ]]; then
                    downloader_section="TRANSMISSION"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_port "${PORT}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_base
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_dir
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_user
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_pass
                    crudini --set "${CONFIG_PATH}" TORRENT tor_downloader_transmission 1
                    DOWNLOADER_CONFIGURED="true"
                fi
            fi
        fi

        if [[ ${CONTAINER_NAME} == "mylar" ]]; then
            local downloader_section

            if [[ ${containers[${DOWNLOADER}]+true} == "true" ]]; then
                info "Linking ${CONTAINER_NAME} to ${DOWNLOADER}..."

                if [[ ${DOWNLOADER} == "nzbget" ]]; then
                    local NZBGET_RESTRICTED_USERNAME
                    local NZBGET_RESTRICTED_PASSWORD
                    NZBGET_RESTRICTED_USERNAME=${API_KEYS[nzbget]%%,*}
                    NZBGET_RESTRICTED_PASSWORD=${API_KEYS[nzbget]#*,}
                    downloader_section="NZBGet"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_port "${PORT}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_priority Default
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_category Books
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_user "${NZBGET_RESTRICTED_USERNAME}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_pass "${NZBGET_RESTRICTED_PASSWORD}"
                    DOWNLOADER_CONFIGURED="true"
                elif [[ ${DOWNLOADER} == "qbittorrent" ]]; then
                    downloader_section="qBittorrent"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}:${PORT}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_label Books
                    crudini --set "${CONFIG_PATH}" "Torrents" "enable_torrents" "True"
                    if [[ $(crudini --set "${CONFIG_PATH}" "Torrents" "minseeds") -eq 0 ]]; then
                        crudini --set "${CONFIG_PATH}" "Torrents" "minseeds" "1"
                    fi
                    DOWNLOADER_CONFIGURED="true"
                elif [[ ${DOWNLOADER} == "transmission" ]]; then
                    downloader_section="Transmission"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_host "${LOCAL_IP}"
                    crudini --set "${CONFIG_PATH}" "${downloader_section}" ${DOWNLOADER}_port "${PORT}"
                    crudini --set "${CONFIG_PATH}" "Torrents" "enable_torrents" "True"
                    if [[ $(crudini --set "${CONFIG_PATH}" "Torrents" "minseeds") -eq 0 ]]; then
                        crudini --set "${CONFIG_PATH}" "Torrents" "minseeds" "1"
                    fi
                    DOWNLOADER_CONFIGURED="true"
                fi
            fi
        fi
    done

    if [[ ${DOWNLOADER_CONFIGURED} != "true" ]]; then
        warn "No Downloaders to configure."
    fi
}

test_configure_add_downloader() {
    warn "CI does not test this script"
}

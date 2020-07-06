#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_add_indexer() {
    info "    - Updating Indexer settings"
    local APPNAME="${1}"
    local APP_DB_PATH="${2}"
    local APP_CONFIG_PATH="${3}"
    local INDEXER_CONFIGURED="false"
    local HYDRA2_CONFIGURED="false"
    debug "APPNAME=${APPNAME}"
    debug "APP_DB_PATH=${APP_DB_PATH}"
    debug "APP_CONFIG_PATH=${APP_CONFIG_PATH}"
    # Get supported indexers
    mapfile -t INDEXERS < <(yq-go r "${DETECTED_DSACDIR}/.data/supported_apps.yml" "indexers" | awk '{gsub("- ",""); print}')

    for INDEXER in "${!INDEXERS[@]}"; do
        local INDEXER_YML
        INDEXER_YML="services.${INDEXER}.labels[com.dockstarter.dsac]"

        if [[ $(run_script 'yml_get' "${INDEXER}" "${APP_YML}.docker.running") == "true" ]]; then
            if [[ ${INDEXER} == "nzbhydra2" || (${INDEXER} == "jackett" && ${HYDRA2_CONFIGURED} != "true") ]]; then
                local INDEXER_PORT
                local INDEXER_BASE_URL
                local INDEXER_TYPE
                local LOCAL_IP
                LOCAL_IP=$(run_script 'detect_local_ip')
                INDEXER_BASE_URL=$(run_script 'yml_get' "${INDEXER}" "${INDEXER_YML}.base_url")
                INDEXER_PORT=$(run_script 'yml_get' "${INDEXER}" "${INDEXER_YML}.ports.default")
                INDEXER_PORT=$(run_script 'yml_get' "${INDEXER}" "${INDEXER_YML}.ports.${INDEXER_PORT}" || echo "${INDEXER_PORT}")
                indexer_url_base="http://${LOCAL_IP}:${INDEXER_PORT}${INDEXER_BASE_URL}"

                if [[ ${INDEXER} == "nzbhydra2" ]]; then
                    INDEXER_TYPE=("usenet" "torrent")
                elif [[ ${INDEXER} == "jackett" ]]; then
                    INDEXER_TYPE=("torrent")
                else
                    fatal "${INDEXER} not supported and this shouldn't have happened..."
                fi

                if [[ ${APPNAME} == "radarr" || ${APPNAME} == "sonarr" || ${APPNAME} == "lidarr" ]]; then
                    info "Linking ${APPNAME} to ${INDEXER}..."
                    local indexer_db_id
                    local indexer_settings
                    local categories
                    local additional_columns
                    local additional_values

                    if [[ ${APPNAME} == "radarr" ]]; then
                        categories="2000,2010,2020,2030,2035,2040,2045,2050,2060"
                    elif [[ ${APPNAME} == "sonarr" ]]; then
                        categories="5030,5040"
                    elif [[ ${APPNAME} == "lidarr" ]]; then
                        categories="3000,3010,3020,3030,3040"
                    else
                        categories=""
                        warn "No categories configured for ${APPNAME}"
                    fi
                    debug "APPNAME=${APPNAME}"
                    debug "categories=${categories}"

                    if [[ ${APPNAME} == "radarr" || ${APPNAME} == "sonarr" ]]; then
                        additional_columns=",EnableSearch"
                        additional_values=",1"
                    elif [[ ${APPNAME} == "lidarr" ]]; then
                        additional_columns=",EnableAutomaticSearch,EnableInteractiveSearch"
                        additional_values=",1,1"
                    else
                        additional_columns=""
                        additional_values=""
                    fi

                    for type in "${INDEXER_TYPE[@]}"; do
                        local indexer_url
                        local indexer_name
                        local api_url
                        debug "Indexer type: ${type}"

                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            config_contract="NewznabSettings"
                            indexer_name="${INDEXER} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            config_contract="TorznabSettings"
                            indexer_name="${INDEXER} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            # Check if using only Jackett
                            if [[ (${INDEXER} == "jackett" && ${HYDRA2_CONFIGURED} != "true") ]]; then
                                api_url = "api/v2.0/indexers/all/results/torznab"
                            else
                                api_url = "torznab"
                            fi
                            if [[ ${INDEXER_BASE_URL} == "/" ]]; then
                                indexer_url="${indexer_url_base}${api_url}"
                            else
                                indexer_url="${indexer_url_base}/${api_url}"
                            fi
                        else
                            fatal "${INDEXER} not supported and this shouldn't have happened..."
                        fi
                        sqlite3 "${APP_DB_PATH}" "INSERT INTO Indexers (Name,Implementation,Settings,ConfigContract,EnableRss${additional_columns})
                                                SELECT '${indexer_name}','${implementation}','{
                                                        \"baseUrl\": \"${indexer_url}\",
                                                        \"multiLanguages\": [],
                                                        \"apiKey\": \"${API_KEYS[${INDEXER}]}\",
                                                        \"categories\": [${categories}],
                                                        \"animeCategories\": [],
                                                        \"removeYear\": false,
                                                        \"searchByTitle\": false }','${config_contract}',1${additional_values}
                                                WHERE NOT EXISTS(SELECT 1 FROM Indexers WHERE name='${indexer_name}');"
                        debug "Get ${INDEXER} DB ID"
                        indexer_db_id=$(sqlite3 "${APP_DB_PATH}" "SELECT id FROM Indexers WHERE Name='${indexer_name}'")
                        debug "${INDEXER} DB ID: ${indexer_db_id}"
                        # Get settings for INDEXER
                        indexer_settings=$(sqlite3 "${APP_DB_PATH}" "SELECT Settings FROM Indexers WHERE id=$indexer_db_id")
                        # Set INDEXER API Key
                        debug "Setting API Key to: ${API_KEYS[${INDEXER}]}"
                        indexer_settings=$(sed 's/"apiKey":.*",/"apiKey": "'"${API_KEYS[${INDEXER}]}"'",/' <<< "$indexer_settings")
                        # Set INDEXER Url
                        debug "Setting URL to: ${indexer_url}"
                        indexer_settings=$(sed 's#"baseUrl":.*",#"baseUrl": "'"${indexer_url}"'",#' <<< "$indexer_settings")
                        # Set categories
                        debug "Setting categories to: [${categories}]"
                        indexer_settings=$(sed 's#"categories":.*,#"categories": ['"${categories}"'],#' <<< "$indexer_settings")
                        #Update the settings for INDEXER
                        debug "Updating DB"
                        sqlite3 "${APP_DB_PATH}" "UPDATE Indexers SET Settings='$indexer_settings' WHERE id=$indexer_db_id"
                    done

                    if [[ ${INDEXER} == "nzbhydra2" ]]; then
                        HYDRA2_CONFIGURED="true"
                    fi

                    INDEXER_CONFIGURED="true"
                fi

                if [[ ${APPNAME} == "lazylibrarian" ]]; then
                    info "Linking ${APPNAME} to ${INDEXER}..."
                    for type in "${INDEXER_TYPE[@]}"; do
                        local indexer_url
                        local indexer_name
                        local indexer_section
                        indexer_section=""

                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            indexer_name="${INDEXER} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            indexer_name="${INDEXER} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${INDEXER_BASE_URL} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                        else
                            fatal "${type} not supported and this shouldn't have happened..."
                        fi

                        for ((i = 0; i <= 10; i++)); do
                            debug "Checking ${implementation}${i}..."
                            #TODO: Change all "grep -c ... -gt 0" to use "grep -p"
                            if [[ $(grep -c "${implementation}${i}" "${APP_CONFIG_PATH}") -gt 0 ]]; then
                                local indexer_name_check
                                indexer_name_check=$(crudini --get "${APP_CONFIG_PATH}" "${implementation}${i}" dispname)
                                if [[ ${indexer_name_check} == "${indexer_name}" ]]; then
                                    indexer_section="${implementation}${i}"
                                    debug "- Updating ${indexer_name}..."
                                    break
                                fi
                            elif [[ -z ${indexer_section} ]]; then
                                indexer_section="${implementation}${i}"
                                debug "- Adding ${indexer_name}..."
                                break
                            fi
                        done

                        if [[ -n ${indexer_section} ]]; then
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" comicsearch
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" audiocat 3030
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" extended 1
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" manual 0
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" bookcat 7000,7020
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" enabled True
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" magcat 7010
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" comiccat 7030
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" dltypes A,C,E,M
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" generalsearch search
                            # Set INDEXER Url
                            debug "Setting URL to: ${indexer_url}"
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" host "${indexer_url}"
                            # Set INDEXER API key
                            debug "Setting API Key to: ${API_KEYS[${INDEXER}]}"
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" api "${API_KEYS[${INDEXER}]}"
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" apilimit 0
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" booksearch book
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" apicount 0
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" dlpriority 0
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" magsearch
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" audiosearch
                            crudini --set "${APP_CONFIG_PATH}" "${indexer_section}" dispname "${indexer_name}"
                        else
                            error "Unable to link ${APPNAME} to ${INDEXER}..."
                            error "You probably have too many providers configured."
                        fi
                    done

                    if [[ ${INDEXER} == "nzbhydra2" ]]; then
                        HYDRA2_CONFIGURED="true"
                    fi

                    INDEXER_CONFIGURED="true"
                fi

                if [[ ${APPNAME} == "mylar" ]]; then
                    info "Linking ${APPNAME} to ${INDEXER}..."
                    for type in "${INDEXER_TYPE[@]}"; do
                        local indexer_url
                        local indexer_name
                        local indexer_section=""
                        local indexer_setting
                        local indexer_regex

                        debug "${type}"
                        if [[ ${type} == "usenet" ]]; then
                            implementation="Newznab"
                            indexer_name="${INDEXER} - Usenet (DSAC)"
                            indexer_url=${indexer_url_base}
                            # Name, URL/Host, Verify SSL, API Key, Newznab UID, Enabled
                            indexer_setting="${indexer_name}, ${indexer_url}, 0, ${API_KEYS[${INDEXER}]}, , 1"
                            indexer_regex="${indexer_name}, http?://*/*, ?, *, *, [0,1],"
                        elif [[ ${type} == "torrent" ]]; then
                            implementation="Torznab"
                            indexer_name="${INDEXER} - Torrent (DSAC)"
                            indexer_url=${indexer_url_base}
                            if [[ ${INDEXER_BASE_URL} == "/" ]]; then
                                indexer_url="${indexer_url_base}torznab"
                            else
                                indexer_url="${indexer_url_base}/torznab"
                            fi
                            # Name, URL/Host, Verify SSL, Torznab Category, Enabled
                            indexer_setting="${indexer_name}, ${indexer_url}, ${API_KEYS[${INDEXER}]}, , 1"
                            indexer_regex="${indexer_name}, http?://*/*, ?, *, [0,1],"
                        else
                            fatal "${type} not supported and this shouldn't have happened..."
                        fi
                        implementation_lower=$(echo "${implementation}" | tr '[:upper:]' '[:lower:]')

                        indexers=$(crudini --get "${APP_CONFIG_PATH}" "${implementation}" "extra_${implementation_lower}s")

                        if [[ ${indexers} == "" ]]; then
                            debug "Adding first ${implementation}"
                            crudini --set "${APP_CONFIG_PATH}" "${implementation}" "extra_${implementation_lower}s" "${indexer_setting}"
                        elif [[ ${indexers} == *"${indexer_name}"* ]]; then
                            debug "Updating ${implementation}"
                            debug "indexers=${indexers}"
                            indexers=${indexers//${indexer_regex}/${indexer_setting}}
                            debug "indexers=${indexers}"
                            crudini --set "${APP_CONFIG_PATH}" "${implementation}" "extra_${implementation_lower}s"
                        else
                            debug "Adding additional ${implementation}"
                            crudini --set "${APP_CONFIG_PATH}" "${implementation}" "extra_${implementation_lower}s" "${indexers}, ${indexer_setting}"
                        fi

                        # Enable to general INDEXER
                        if [[ ${type} == "usenet" ]]; then
                            crudini --set "${APP_CONFIG_PATH}" "${implementation}" "${implementation_lower}" "true"
                        elif [[ ${type} == "torrent" ]]; then
                            crudini --set "${APP_CONFIG_PATH}" "${implementation}" "enable_${implementation_lower}" "true"
                        fi

                        provider_order=$(crudini --get "${APP_CONFIG_PATH}" "Providers" "provider_order")
                        debug "Providers:${provider_order}"
                        if [[ ${provider_order} == "" || ${provider_order} == "0," ]]; then
                            debug "Adding first provider to list"
                            crudini --set "${APP_CONFIG_PATH}" "Providers" "provider_order" "0, ${indexer_name}"
                        elif [[ ${provider_order} == *"${indexer_name}"* ]]; then
                            debug "Provider already exists in list"
                        else
                            debug "Adding provider to list"
                            IFS="," read -ra provider_order_list <<< "${provider_order}"
                            for provider in "${provider_order_list[@]}"; do
                                local re='^[0-9]+$'
                                if [[ ${provider} =~ ${re} ]]; then
                                    debug "provider:${provider}"
                                    index=${provider}
                                fi
                            done
                            index=$((index + 1))
                            debug "index:${index}"
                            provider_order="${provider_order}, ${index}, ${indexer_name}"
                            crudini --set "${APP_CONFIG_PATH}" "Providers" "provider_order" "${provider_order}"
                            debug "Providers:${provider_order}"
                        fi
                    done

                    if [[ ${INDEXER} == "nzbhydra2" ]]; then
                        HYDRA2_CONFIGURED="true"
                    fi

                    INDEXER_CONFIGURED="true"
                fi
            fi
        fi
    done

    if [[ ${INDEXER_CONFIGURED} != "true" ]]; then
        warn "No Indexers to configure."
    fi
}

test_configure_add_indexer() {
    warn "CI does not test this script"
}

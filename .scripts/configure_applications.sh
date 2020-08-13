#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_applications() {
    info "Configuring ${1} applications"
    local APP_TYPE=${1}
    local APP_CATEGORY
    local APPNAME
    local CONTAINER_ID
    local CONFIG_SOURCE
    local CONFIG_FILE
    local CONFIG_PATH
    local DB_FILE
    local DB_PATH

    if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
        mapfile -t APP_CATEGORIES < <(echo "${APP_TYPE}")
    else
        mapfile -t APP_CATEGORIES < <(yq-go r --printMode p "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}.*")
    fi
    #shellcheck disable=SC2154
    for APP_CATEGORY in "${APP_CATEGORIES[@]}"; do
        APP_CATEGORY="${APP_CATEGORY#*.}"
        if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
            mapfile -t APPS < <(run_script 'yml_get' "" "${APP_TYPE}" "${DETECTED_DSACDIR}/.data/configure_apps.yml" | awk '{gsub("- ",""); print}')
            info "- ${APP_TYPE^}"
        else
            mapfile -t APPS < <(run_script 'yml_get' "" "${APP_TYPE}.${APP_CATEGORY}" "${DETECTED_DSACDIR}/.data/configure_apps.yml" | awk '{gsub("- ",""); print}')
            info "- ${APP_TYPE^} ${APP_CATEGORY^}"
        fi
        for APPNAME in "${APPS[@]}"; do
            local APP_YML
            APP_YML="services.${APPNAME}.labels[com.dockstarter.dsac]"
            if [[ $(run_script 'yml_get' "${APPNAME}" "${APP_YML}.docker.running") == "true" ]]; then
                info "${APPNAME}"
                CONTAINER_ID=$(run_script 'yml_get' "${APPNAME}" "${APP_YML}.docker.container_id")
                CONFIG_SOURCE=$(run_script 'yml_get' "${APPNAME}" "${APP_YML}.config.source")
                CONFIG_FILE=$(run_script 'yml_get' "${APPNAME}" "${APP_YML}.config.file")
                DB_FILE=$(run_script 'yml_get' "${APPNAME}" "${APP_YML}.config.database")

                if [[ -n ${CONFIG_FILE} ]]; then
                    CONFIG_PATH="${CONFIG_SOURCE}/${CONFIG_FILE}"
                else
                    CONFIG_PATH=""
                fi
                if [[ -n ${DB_FILE} ]]; then
                    DB_PATH="${CONFIG_SOURCE}/${DB_FILE}"
                else
                    DB_PATH=""
                fi

                info "Stopping ${APPNAME} (${CONTAINER_ID}) to apply changes..."
                if [[ $(docker stop "${CONTAINER_ID}" > /dev/null) ]]; then
                    if [[ ${APPNAME} == "bazarr" || ${APPNAME} == "nzbhydra2" ]]; then
                        run_script "configure_${APPNAME}" "${APPNAME}" "${DB_PATH}" "${CONFIG_PATH}"
                    elif [[ ${APP_CATEGORY} == "usenet" || ${APP_CATEGORY} == "torrent" ]]; then
                        run_script "configure_${APP_CATEGORY}_downloader" "${APPNAME}" "${DB_PATH}" "${CONFIG_PATH}"
                    elif [[ ${APP_TYPE} == "indexers" ]]; then
                        debug "Not doing anything with ${APPNAME} right now..."
                    else
                        run_script "configure_add_indexer" "${APPNAME}" "${DB_PATH}" "${CONFIG_PATH}"
                        run_script "configure_add_downloader" "${APPNAME}" "${DB_PATH}" "${CONFIG_PATH}"
                    fi

                    info "Starting ${APPNAME} (${CONTAINER_ID})..."
                    docker start "${CONTAINER_ID}" > /dev/null || error "Unable to start container..."

                    info "Done configuring ${APPNAME}"
                else
                    error "       Unable to stop container. Skipping configuration."
                fi
            fi
        done
        if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
            info "- Done configuring ${APP_TYPE}"
            break
        else
            info "- Done configuring ${APP_CATEGORY} ${APP_TYPE}"
        fi
    done
}

test_configure_applications() {
    warn "Test not configured yet."
}

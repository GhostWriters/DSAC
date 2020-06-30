#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_applications() {
    info "Configuring ${1} applications"
    local APP_TYPE=${1}
    local APP_CATEGORY
    local APP_NAME
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
        if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
            mapfile -t APPS < <(run_script 'yml_get' "" "${APP_TYPE}" "${DETECTED_DSACDIR}/.data/configure_apps.yml" | awk '{gsub("- ",""); print}')
            info "- ${APP_TYPE}"
        else
            mapfile -t APPS < <(run_script 'yml_get' "" "${APP_TYPE}.${APP_CATEGORY}" "${DETECTED_DSACDIR}/.data/configure_apps.yml" | awk '{gsub("- ",""); print}')
            info "- ${APP_TYPE} ${APP_CATEGORY} "
        fi
        for APP_NAME in "${APPS[@]}"; do
            local CONTAINER_YML
            CONTAINER_YML="services.${INDEXER}.labels[com.dockstarter.dsac]"
            if [[ $(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.docker.running") == "true" ]]; then
                info "${APP_NAME}"
                CONTAINER_ID=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.docker.container_id")
                CONFIG_SOURCE=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.config.source")
                CONFIG_FILE=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.config.file")
                DB_FILE=$(run_script 'yml_get' "${APP_NAME}" "${CONTAINER_YML}.config.database")

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

                info "Stopping ${APP_NAME} (${CONTAINER_ID}) to apply changes..."
                docker stop "${CONTAINER_ID}" > /dev/null || error "       Unable to stop container..."

                if [[ ${APP_NAME} == "bazarr" || ${APP_NAME} == "nzbhydra2" ]]; then
                    run_script "configure_${APP_NAME}" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                elif [[ ${APP_CATEGORY} == "usenet" || ${APP_CATEGORY} == "torrent" ]]; then
                    run_script "configure_${APP_CATEGORY}_downloader" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                elif [[ ${APP_TYPE} == "indexers" ]]; then
                    debug "Not doing anything with ${APP_NAME} right now..."
                else
                    run_script "configure_add_indexer" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                    run_script "configure_add_downloader" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                fi

                info "Starting ${APP_NAME} (${CONTAINER_ID})..."
                docker start "${CONTAINER_ID}" > /dev/null || error "Unable to start container..."

                info "Done configuring ${APP_NAME}"
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

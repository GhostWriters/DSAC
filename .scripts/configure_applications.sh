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
    local CONTAINER_YML_FILE

    mapfile -t app_categories < <(yq-go r --printMode p "${DETECTED_DSACDIR}/.data/configure_apps.yml" '*')
    #shellcheck disable=SC2154
    for app_category_index in "${!app_categories[@]}"; do
        APP_CATEGORY=${app_categories[${app_category_index}]//\"/}
        if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
            mapfile -t apps < <(yq-go r "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}" | awk '{gsub("- ",""); print}')
            info "- ${APP_TYPE}"
        else
            mapfile -t apps < <(yq-go r "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}.${APP_CATEGORY}" | awk '{gsub("- ",""); print}')
            info "- ${APP_CATEGORY} ${APP_TYPE}"
        fi
        for app_index in "${!apps[@]}"; do
            APP_NAME=${apps[${app_index}]//\"/}
            CONTAINER_YML_FILE="${DETECTED_DSACDIR}/.data/apps/${APP_NAME}/${APP_NAME}.yml"
            if [[ -f ${CONTAINER_YML_FILE} ]]; then
                info "  - ${APP_NAME}"
                CONTAINER_YML_FILE
                CONTAINER_ID=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.docker.container_id")
                CONFIG_SOURCE=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.source")
                CONFIG_FILE=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.file")
                DB_FILE=$(yq-go r "${CONTAINER_YML_FILE}" "${CONTAINER_YML}.config.database")

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

                info "    - Stopping ${APP_NAME} (${CONTAINER_ID}) to apply changes..."
                docker stop "${CONTAINER_ID}" > /dev/null || error "       Unable to stop container..."

                if [[ ${APP_NAME} == "bazarr" || ${APP_NAME} == "hydra2" ]]; then
                    run_script "configure_${APP_NAME}" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                elif [[ ${APP_CATEGORY} == "usenet" || ${APP_CATEGORY} == "torrent" ]]; then
                    run_script "configure_${APP_CATEGORY}_downloader" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                elif [[ ${APP_TYPE} == "indexers" ]]; then
                    debug "    - Not doing anything with ${APP_NAME} right now..."
                else
                    run_script "configure_add_indexer" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                    run_script "configure_add_downloader" "${APP_NAME}" "${DB_PATH}" "${CONFIG_PATH}"
                fi

                info "    - Starting ${APP_NAME} (${CONTAINER_ID})..."
                docker start "${CONTAINER_ID}" > /dev/null || error "       Unable to start container..."

                info "  - Done configuring ${APP_NAME}"
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

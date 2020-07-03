#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_nzbhydra2() {
    local APPNAME=${1}
    # local db_path=${2}
    local APP_CONFIG_PATH=${3}
    local APP_YML
    APP_YML="services.${CONTAINER_NAME}.labels[com.dockstarter.dsac]"

    if [[ $(run_script 'yml_get' "${CONTAINER_NAME}" "${APP_YML}.docker.running") == "true" ]]; then
        local LOCAL_IP
        LOCAL_IP=$(run_script 'detect_local_ip')
        local JACKETT_APP_YML="services.jackett.labels[com.dockstarter.dsac]"
        if [[ $(run_script 'yml_get' "jackett" "${RADARR_APP_YML}.docker.running") == "true" ]]; then
            local JACKETT_CONFIG_PATH
            JACKETT_CONFIG_PATH="$(run_script 'yml_get' "jackett" "${JACKETT_APP_YML}.config.source")/Jackett"
            local JACKETT_CONFIG_FILE
            JACKETT_CONFIG_FILE="${JACKETT_CONFIG_PATH}/$(run_script 'yml_get' "jackett" "${JACKETT_APP_YML}.config.file")"
            local JACKETT_INDEXERS_PATH
            JACKETT_INDEXERS_PATH="${JACKETT_CONFIG_PATH}/Indexers"
            local JACKETT_PORT
            JACKETT_PORT=$(run_script 'yml_get' "jackett" "${JACKETT_APP_YML}.ports.default")
            JACKETT_PORT=$(run_script 'yml_get' "jackett" "${JACKETT_APP_YML}.ports.${JACKETT_PORT}" || echo "${JACKETT_PORT}")
            local JACKETT_BASE
            JACKETT_BASE=$(jq -r '.BasePathOverride' "${JACKETT_CONFIG_FILE}" || echo "/")
            local JACKET_URL
            JACKET_URL="http://${LOCAL_IP}:${JACKETT_PORT}${JACKETT_BASE}"

            if [[ -d ${JACKETT_INDEXERS_PATH} ]]; then
                for file in "${JACKETT_INDEXERS_PATH}"/*.json; do
                    debug "       Processing $file file..."
                    local TRACKER
                    TRACKER=${file##*/}
                    TRACKER=${TRACKER%.json}
                    debug "       TRACKER=${TRACKER}"
                    # Get indexers from Hydra2
                    HYDRA_INDEXER_NAME="Jackett - ${TRACKER} (DSAC)"
                    debug "       Checking for '${HYDRA_INDEXER_NAME}' in Hydra2 indexers list"
                    if ! yq-go r "${APP_CONFIG_PATH}" "indexers[*].name" | grep -q "${HYDRA_INDEXER_NAME}"; then
                        debug "       - Not found..."
                        HYDRA_INDEXER_HOST="${JACKET_URL}/api/v2.0/indexers/${TRACKER}/results/torznab/"

                        local HITMP="${DETECTED_DSACDIR}/.tmp/hydra2_indexer.yml"
                        mkdir -p "${DETECTED_DSACDIR}/.tmp/"
                        touch "${HITMP}" || error "Unable to create temporary Hydra2 indexer file."
                        sudo chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${HITMP}" > /dev/null 2>&1 || true # This line should always use sudo
                        if [[ -f ${HITMP} ]]; then
                            cat "${DETECTED_DSACDIR}/.data/hydra2_indexer_defaults.yml" > "${HITMP}"
                            yq-go w "${HITMP}" "indexers[0].name" "TEST" -i
                            yq-go w "${HITMP}" "indexers[0].apiKey" "\"${API_KEYS[jackett]}\"" -i
                            yq-go w "${HITMP}" "indexers[0].name" "\"${HYDRA_INDEXER_NAME}\"" -i
                            yq-go w "${HITMP}" "indexers[0].host" "\"${HYDRA_INDEXER_HOST}\"" -i
                            yq-go w "${HITMP}" "indexers[0].score" "4" -i
                            yq-go m "${APP_CONFIG_PATH}" "${HITMP}" -i
                            rm -f "${HITMP}" || warn "Temporary Hydra2 indexer file could not be removed."
                        fi
                    else
                        debug "       - Found..."
                    fi
                done
            else
                info "       - No trackers to add to Hydra2"
            fi
        fi
    fi
}

test_configure_nzbhydra2() {
    warn "CI does not test this script"
}

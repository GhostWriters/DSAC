#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

configure_hydra2() {
    local container_name=${1}
    local db_path=${2}
    local config_path=${3}

    # shellcheck disable=SC2154,SC2001
    if [[ ${containers[$container_name]+true} == "true" ]]; then
        local LOCAL_IP
        LOCAL_IP=$(run_script 'detect_local_ip')
        if [[ ${containers[jackett]+true} == "true" ]]; then
            # Get trackers from Jackett CONFIG_PATH/Indexers/*.json
            jackett_config_source=$(jq -r '.config_source' <<< "${containers[jackett]}")
            jackett_config_file=$(jq -r '.config.file' <<< "${containers[jackett]}")
            jackett_config_path="${jackett_config_source}/${jackett_config_file}"
            jackett_indexers_path="/home/matty/.config/appdata/jackett/Jackett/Indexers"
            jackett_base=$(jq -r '.base_url' <<< "${containers[jackett]}")
            jackett_port=$(jq -r '.ports["9117"]' <<< "${containers[jackett]}")
            jackett_url_base="http://${LOCAL_IP}:${jackett_port}${jackett_base}"
            #${jackett_config_source}/Jackett/Indexers/*.json
            if [[ -d "${jackett_indexers_path}" ]]; then
                for file in ${jackett_indexers_path}/*.json; do
                    debug "       Processing $file file..."
                    local tracker
                    tracker=${file##*/}
                    tracker=${tracker%.json}
                    debug "       tracker=${tracker}"
                    # Get indexers from Hydra2
                    hydra_indexer_name="Jackett - ${tracker} (DSAC)"
                    debug "       Checking for '${hydra_indexer_name} in Hydra2 indexers list'"
                    if ! yq-go r "${config_path}" "indexers[*].name" | grep -q "${hydra_indexer_name}"; then
                        debug "       - Not found..."
                        hydra_indexer_host="${jackett_url_base}/api/v2.0/indexers/${tracker}/results/torznab/"

                        local HITMP="${DETECTED_DSACDIR}/.tmp/hydra2_indexer.yml"
                        mkdir -p "${DETECTED_DSACDIR}/.tmp/"
                        touch "${HITMP}" || error "Unable to create temporary Hydra2 indexer file."
                        sudo chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${HITMP}" > /dev/null 2>&1 || true # This line should always use sudo
                        if [[ -f "${HITMP}" ]]; then
                            cat "${DETECTED_DSACDIR}/.data/hydra2_indexer_defaults.yml" > "${HITMP}"
                            yq-go w "${HITMP}" "indexers[0].name" "TEST" -i
                            yq-go w "${HITMP}" "indexers[0].apiKey" "\"${API_KEYS[jackett]}\"" -i
                            yq-go w "${HITMP}" "indexers[0].name" "\"${hydra_indexer_name}\"" -i
                            yq-go w "${HITMP}" "indexers[0].host" "\"${hydra_indexer_host}\"" -i
                            yq-go w "${HITMP}" "indexers[0].score" "4" -i
                            yq-go m "${config_path}" "${HITMP}" -i
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

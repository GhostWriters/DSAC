#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_local() {
    info "Updating DSAC from local development files: ${DETECTED_HOMEDIR}/${LOCAL_DIR}"

    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/main.sh" "${DETECTED_DSACDIR}/main.sh"

    if [[ -d "${DETECTED_DSACDIR}/.scripts" ]]; then
        sudo rm -r "${DETECTED_DSACDIR}/.scripts"
    fi
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" "${DETECTED_DSACDIR}"

    if [[ -d "${DETECTED_DSACDIR}/.data" ]]; then
        sudo rm -r "${DETECTED_DSACDIR}/.data"
    fi
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.data" "${DETECTED_DSACDIR}"

    if [[ -d "${DETECTED_DSACDIR}/.tests" ]]; then
        sudo rm -r "${DETECTED_DSACDIR}/.tests"
    fi
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" "${DETECTED_DSACDIR}"

    if [[ -d "${DETECTED_DSACDIR}/compose" ]]; then
        sudo rm -r "${DETECTED_DSACDIR}/compose"
    fi
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" "${DETECTED_DSACDIR}"
}

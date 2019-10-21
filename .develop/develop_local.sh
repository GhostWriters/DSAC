#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_local() {
    info "Updating DSAC from local development files: ${DETECTED_HOMEDIR}/${LOCAL_DIR}"

    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/main.sh" "${DETECTED_DSACDIR}/main.sh"
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/dsac_manifest.csv" "${DETECTED_DSACDIR}/dsac_manifest.csv"

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" ]]; then
        if [[ -d "${DETECTED_DSACDIR}/.scripts" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.scripts"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.data" ]]; then
        if [[ -d "${DETECTED_DSACDIR}/.data" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.data"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.data" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" ]]; then
        if [[ -d "${DETECTED_DSACDIR}/.tests" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.tests"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" ]]; then
        if [[ -d "${DETECTED_DSACDIR}/compose" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/compose"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" "${DETECTED_DSACDIR}"
    fi
}

test_develop_local() {
    warn "CI does not test this script"
}

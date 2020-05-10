#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_local() {
    info "Updating DSAC from local development files: ${DETECTED_HOMEDIR}/${LOCAL_DIR}"

    info "Updating ${DETECTED_DSACDIR}/main.sh"
    sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/main.sh" "${DETECTED_DSACDIR}/main.sh"
    #sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/dsac_manifest.csv" "${DETECTED_DSACDIR}/dsac_manifest.csv"

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.develop" ]]; then
        info "Updating ${DETECTED_DSACDIR}/.develop"
        if [[ -d "${DETECTED_DSACDIR}/.develop" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.develop"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.develop" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" ]]; then
        info "Updating ${DETECTED_DSACDIR}/.scripts"
        if [[ -d "${DETECTED_DSACDIR}/.scripts" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.scripts"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.apps" ]]; then
        info "Updating ${DETECTED_DSACDIR}/.apps"
        if [[ -d "${DETECTED_DSACDIR}/.apps" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.apps"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.apps" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.data" ]]; then
        info "Updating ${DETECTED_DSACDIR}/.data"
        if [[ -d "${DETECTED_DSACDIR}/.data" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.data"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.data" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" ]]; then
        info "Updating ${DETECTED_DSACDIR}/.tests"
        if [[ -d "${DETECTED_DSACDIR}/.tests" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/.tests"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" "${DETECTED_DSACDIR}"
    fi

    if [[ -d "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" ]]; then
        info "Updating ${DETECTED_DSACDIR}/compose"
        if [[ -d "${DETECTED_DSACDIR}/compose" ]]; then
            sudo rm -r "${DETECTED_DSACDIR}/compose"
        fi
        sudo cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" "${DETECTED_DSACDIR}"
    fi
}

test_develop_local() {
    warn "CI does not test this script"
}

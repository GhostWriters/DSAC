#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_local() {
    info "Updating DSAC from local development files: ${DETECTED_HOMEDIR}/${LOCAL_DIR}"
    cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/main.sh" "${DETECTED_DSACDIR}/main.sh"
    cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.scripts" "${DETECTED_DSACDIR}"
    cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/.tests" "${DETECTED_DSACDIR}"
    cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" "${DETECTED_DSACDIR}"
}

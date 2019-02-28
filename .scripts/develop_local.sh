#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_local() {
    info "Updating DSAC from local development files: ${DETECTED_HOMEDIR}/${LOCAL_DIR}"
    cd "${DETECTED_HOMEDIR}/${LOCAL_DIR}"
    find . -iname '*.sh' -exec cp --parents {} "${DETECTED_DSACDIR}" \;
    cd "${DETECTED_HOMEDIR}"
}

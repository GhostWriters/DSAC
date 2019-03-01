#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_preconfigured_apps() {
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Getting DSAC apps for quick setup."
        while IFS= read -r line; do
            local APPNAME
            APPNAME=${line^^}
            info "APPNAME=${APPNAME}"
        done < <(grep '_DSAC_QUICKSETUP=TRUE$' < "${DETECTED_DSACDIR}/dsac_apps")
    fi
}
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install_dockstarter() {
    if [[ ! -d ${DETECTED_HOMEDIR}/.docker/.git ]]; then
        warning "Attempting to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
        git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_HOMEDIR}/.docker" || fatal "Failed to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."
        info "Performing first run install."
        (bash "${DETECTED_HOMEDIR}/.docker/main.sh" "-i") || fatal "Failed first run install, please reboot and try again."
    fi
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_yum_repos() {
    info "Installing EPEL and IUS repositories."
    local GET_IUS
    GET_IUS=$(mktemp) || fatal "Failed to create temporary storage for IUS repo install."
    curl -fsSL setup.ius.io -o "${GET_IUS}" > /dev/null 2>&1 || fatal "Failed to get IUS install script."
    bash "${GET_IUS}" > /dev/null 2>&1 || warn "Failed to install IUS."
    rm -f "${GET_IUS}" || warn "Temporary setup.ius.io file could not be removed."
}

test_pm_yum_repos() {
    # run_script 'pm_yum_repos'
    warn "Travis does not test pm_yum_repos."
}

#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

symlink_dsac() {
    run_script 'set_permissions' "${SCRIPTNAME}"

    # /usr/bin/dsac
    if [[ -L "/usr/bin/dsac" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/bin/dsac)" ]]; then
        info "Attempting to remove /usr/bin/dsac symlink."
        rm -f "/usr/bin/dsac" || fatal "Failed to remove /usr/bin/dsac"
    fi
    if [[ ! -L "/usr/bin/dsac" ]]; then
        info "Creating /usr/bin/dsac symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/bin/dsac || fatal "Failed to create /usr/bin/dsac symlink."
    fi

    # /usr/local/bin/dsac
    if [[ -L "/usr/local/bin/dsac" ]] && [[ ${SCRIPTNAME} != "$(readlink -f /usr/local/bin/dsac)" ]]; then
        info "Attempting to remove /usr/local/bin/dsac symlink."
        rm -f "/usr/local/bin/dsac" || fatal "Failed to remove /usr/local/bin/dsac"
    fi
    if [[ ! -L "/usr/local/bin/dsac" ]]; then
        info "Creating /usr/local/bin/dsac symbolic link for DockSTARTer App Config."
        ln -s -T "${SCRIPTNAME}" /usr/local/bin/dsac || fatal "Failed to create /usr/local/bin/dsac symlink."
    fi
}

test_symlink_dsac() {
    warn "CI does not test this script"
}

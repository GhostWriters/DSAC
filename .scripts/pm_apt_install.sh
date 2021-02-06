#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

pm_apt_install() {
    info "Installing dependencies."
    apt-get -y install apt-transport-https curl git grep sed whiptail sqlite3 crudini jq > /dev/null 2>&1 || fatal "Failed to install dependencies from apt."
}

test_pm_apt_install() {
    run_script 'pm_apt_install'
}

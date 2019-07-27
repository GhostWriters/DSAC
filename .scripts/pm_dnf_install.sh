#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

pm_dnf_install() {
    info "Installing dependencies."
    dnf -y install curl git grep newt python3 python3-pip rsync sed whiptail sqlite3 crudini jq > /dev/null 2>&1 || fatal "Failed to install dependencies from dnf."
    # https://cryptography.io/en/latest/installation/#building-cryptography-on-linux
    dnf -y install redhat-rpm-config gcc libffi-devel python3-devel openssl-devel > /dev/null 2>&1 || fatal "Failed to install python cryptography dependencies from dnf."
}

test_pm_dnf_install() {
    # run_script 'pm_dnf_install'
    warn "Travis does not test pm_dnf_install."
}

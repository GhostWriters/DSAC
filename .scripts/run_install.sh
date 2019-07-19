#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    run_script 'update_system'
    run_script 'install_yq'
    run_script 'set_permissions'
    run_script 'request_reboot' || return 1
}

test_run_install() {
    run_script 'run_install'
}

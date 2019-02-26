#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_install() {
    run_script 'update_system'
    run_script 'install_yq' force
    run_script 'set_permissions'
    run_script 'request_reboot' || return 1
}

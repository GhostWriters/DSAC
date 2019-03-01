#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_dockstarter() {
    if [[ ! -d ${DETECTED_HOMEDIR}/.docker/.git ]]; then
        run_script 'run_install_dockstarter'
    if
}
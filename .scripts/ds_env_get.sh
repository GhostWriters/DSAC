#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ds_env_get() {
    local GET_VAR=${1:-}
    grep --color=never -Po "^${GET_VAR}=\K.*" "${DETECTED_DSDIR}/compose/.env" || true
}

test_ds_env_get() {
    run_script 'run_dockstarter' install
    run_script 'ds_env_get' DOCKERCONFDIR
}

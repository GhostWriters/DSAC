#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

yml_set() {
    local APPNAME=${1:-}
    local SET_VAR=${2:-}
    local NEW_VAL=${3:-}
    local FILE_PATH=${4:-}
    local FILENAME=${APPNAME,,}
    run_script 'install_yq'
    if [[ -z ${FILE_PATH} ]]; then
        FILE_PATH="${DETECTED_DSACDIR}/.data/apps/${FILENAME}.yml"
    fi
    yq-go w -i "${FILE_PATH}" "${SET_VAR}" "${NEW_VAL}" || fatal "Failed to set '${SET_VAR}'"
}

test_yml_set() {
    run_script 'yml_get' PORTAINER "services..labels[com.dockstarter.dsac]"
}

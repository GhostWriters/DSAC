#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

yml_get() {
    local APPNAME=${1:-}
    local GET_VAR=${2:-}
    local FILE_PATH=${3:-}
    local FILENAME=${APPNAME,,}
    run_script 'install_yq'
    if [[ -z ${FILE_PATH} ]]; then
        FILE_PATH="${DETECTED_DSACDIR}/.data/apps/${FILENAME}.yml"
    fi
    /usr/local/bin/yq-go r "${FILE_PATH}" "${GET_VAR}" 2> /dev/null || return 1
}

test_yml_get() {
    warn "CI does not test this script"
}

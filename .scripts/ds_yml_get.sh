#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ds_yml_get() {
    local APPNAME=${1:-}
    local GET_VAR=${2:-}
    local FILENAME=${APPNAME,,}
    run_script 'install_yq'
    /usr/local/bin/yq-go m "${DETECTED_DSDIR}"/compose/.apps/"${FILENAME}"/*.yml 2> /dev/null | /usr/local/bin/yq-go r - "${GET_VAR}" 2> /dev/null | grep -v '^null$' || return 1
}

test_ds_yml_get() {
    run_script 'run_dockstarter' install
    run_script 'ds_yml_get' PORTAINER "services.portainer.labels[com.dockstarter.appinfo.nicename]"
}

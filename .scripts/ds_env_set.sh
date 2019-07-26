#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ds_env_set() {
    local SET_VAR=${1:-}
    local NEW_VAL=${2:-}
    local VAR_VAL
    VAR_VAL=$(grep --color=never "^${SET_VAR}=" "${DETECTED_DSDIR}/compose/.env") || fatal "Failed to find ${SET_VAR} in ${DETECTED_DSDIR}/compose/.env"
    # https://stackoverflow.com/questions/29613304/is-it-possible-to-escape-regex-metacharacters-reliably-with-sed/29613573#29613573
    local SED_FIND
    SED_FIND=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "${VAR_VAL}")
    local SED_REPLACE
    SED_REPLACE=$(sed 's/[&/\]/\\&/g' <<< "${SET_VAR}=${NEW_VAL}")
    sed -i "s/^${SED_FIND}$/${SED_REPLACE}/" "${DETECTED_DSDIR}/compose/.env" || fatal "Failed to set ${SED_REPLACE}"
}

test_ds_env_set() {
    # run_script 'appvars_create' PORTAINER
    # run_script 'ds_env_set' PORTAINER_ENABLED false
    # run_script 'ds_env_set' PORTAINER_ENABLED
    # run_script 'appvars_purge' PORTAINER
    warning "ds_env_set not currently configured."
}
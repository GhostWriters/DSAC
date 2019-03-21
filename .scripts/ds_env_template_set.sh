#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ds_env_template_set() {
    local SET_VAR
    SET_VAR=${1:-}
    local NEW_VAL
    NEW_VAL=${2:-}
    local VAR_VAL
    VAR_VAL=$(grep "^${SET_VAR}=" "${DETECTED_DSDIR}/compose/.env.template" | xargs) || fatal "Failed to find ${SET_VAR} in ${DETECTED_HOMEDIR}/.docker/compose/.env.template"
    # https://stackoverflow.com/a/29613573/1384186
    local SED_FIND
    SED_FIND=$(sed 's/[^^]/[&]/g; s/\^/\\^/g' <<< "${VAR_VAL}")
    local SED_REPLACE
    SED_REPLACE=$(sed 's/[&/\]/\\&/g' <<< "${SET_VAR}=${NEW_VAL}")
    sed -i "s/^${SED_FIND}$/${SED_REPLACE}/" "${DETECTED_DSDIR}/compose/.env.template" || fatal "Failed to set ${SED_REPLACE}"
}

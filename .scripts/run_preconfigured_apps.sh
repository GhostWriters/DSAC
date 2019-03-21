#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_preconfigured_apps() {
    #Addd DSAC .env.template to DS .env.template
    cp "${DETECTED_DSDIR}/compose/.env.template" "${DETECTED_DSACDIR}/compose/.env.dsac_template.new"
    cat "${DETECTED_DSACDIR}/compose/.env.dsac_template" >> "${DETECTED_DSDIR}/compose/.env.dsac_template.new"
    mv "${DETECTED_DSACDIR}/compose/.env.dsac_template.new" "${DETECTED_DSACDIR}/compose/.env.template"
    #Copy DSAC compose files to DS
    cp -r "${DETECTED_HOMEDIR}/${LOCAL_DIR}/compose" "${DETECTED_DSDIR}"
    #Update DS .env.template
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        info "Getting DSAC apps and setting DS .env.template for quick setup."
        while IFS= read -r line; do
            local APPNAME
            APPNAME=${line^^}
            local SET_VAR
            local SET_VAL
            SET_VAR="${APPNAME}_ENABLED"
            SET_VAL="true"
            run_script 'ds_inject_env_template' "${APPNAME}" "${SET_VAR}" "${SET_VAL}"
            SET_VAR="${APPNAME}_ENABLED"
            SET_VAL="true"
            run_script 'ds_inject_env_template' "${APPNAME}" "${SET_VAR}" "${SET_VAL}"
            SET_VAR="${APPNAME}_BACKUP_CONFIG"
            SET_VAL="true"
        done < <(grep '_DSAC_QUICKSETUP=TRUE$' < "${DETECTED_DSACDIR}/dsac_apps")
    fi
}

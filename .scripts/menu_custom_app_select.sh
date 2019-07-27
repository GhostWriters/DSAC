#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_custom_app_select() {
    run_script 'install_yq'
    local APPLIST=()

    while IFS= read -r line; do
        local APPNAME=${line^^}
        local FILENAME=${APPNAME,,}
        if [[ -d ${DETECTED_DSDIR}/compose/.apps/${FILENAME}/ ]]; then
            if [[ -f ${DETECTED_DSDIR}/compose/.apps/${FILENAME}/${FILENAME}.yml ]]; then
                if [[ -f ${DETECTED_DSDIR}/compose/.apps/${FILENAME}/${FILENAME}.${ARCH}.yml ]]; then
                    local APPNICENAME
                    APPNICENAME=$(run_script 'ds_yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appinfo.nicename]" || echo "${APPNAME}")
                    local APPDESCRIPTION
                    APPDESCRIPTION=$(run_script 'ds_yml_get' "${APPNAME}" "services.${FILENAME}.labels[com.dockstarter.appinfo.description]" || echo "! Missing description !")
                    local APPONOFF
                    if [[ $(run_script 'ds_env_get' "${APPNAME}_ENABLED") == true ]]; then
                        APPONOFF="on"
                    else
                        APPONOFF="off"
                    fi
                    if grep -q "${APPNAME}_DSAC_SUPPORTED=TRUE$" "${DETECTED_DSACDIR}/.data/dsac_apps"; then
                        APPDESCRIPTION="(DSAC Supported) ${APPDESCRIPTION}"
                    fi
                    APPLIST+=("${APPNICENAME}" "${APPDESCRIPTION}" "${APPONOFF}")
                fi
            fi
        fi
    done < <(ls -A "${DETECTED_DSDIR}/compose/.apps/")

    local SELECTEDAPPS
    if [[ ${CI:-} == true ]]; then
        SELECTEDAPPS="Cancel"
    else
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer App Config" --separate-output --checklist 'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.' 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi
    if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
        return 1
    else
        info "Disabling all apps."
        while IFS= read -r line; do
            local APPNAME=${line%%_ENABLED=true}
            run_script 'ds_env_set' "${APPNAME}_ENABLED" false
        done < <(grep '_ENABLED=true$' < "${DETECTED_DSDIR}/compose/.env")

        info "Enabling selected apps."
        while IFS= read -r line; do
            local APPNAME=${line^^}
            debug "APPNAME=${APPNAME}"
            (ds -a "${APPNAME}")
            run_script 'ds_env_set' "${APPNAME}_ENABLED" true
        done < <(echo "${SELECTEDAPPS}")

        (ds -r)
    fi
}

test_menu_custom_app_select() {
    warn "Travis does not test menu_ds_app_select."
}

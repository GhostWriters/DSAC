#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_app_select() {
    local APPLIST
    APPLIST=()

    while IFS= read -r line; do
        local APPNAME
        APPNAME=${line%%_DSAC_SUPPORTED=*}
        local APPDESCRIPTION
        APPDESCRIPTION=$(grep "${APPNAME}_DESCRIPTION" "${DETECTED_DSACDIR}/dsac_apps")
        APPDESCRIPTION=${APPDESCRIPTION##*_DESCRIPTION=}
        APPDESCRIPTION=${APPDESCRIPTION//\"/}
        local APPONOFF
        APPONOFF="off"

        APPLIST+=("${APPNAME}" "${APPDESCRIPTION}" "${APPONOFF}")
    done < <(grep '_DSAC_SUPPORTED=TRUE$' < "${DETECTED_DSACDIR}/dsac_apps")

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        local SELECTEDAPPS
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer App Config" --separate-output --checklist 'Choose which apps you would like to install:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.' 0 0 0 "${APPLIST[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
            return 1
        else
            info "Showing selected DSAC apps."
            while IFS= read -r line; do
                local APPNAME
                APPNAME=${line^^}
                info "APPNAME=${APPNAME}"
            done < <(echo "${SELECTEDAPPS}")
        fi
    fi
}

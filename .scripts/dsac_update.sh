#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_update() {
    local DSAC_BRANCH
    if [[ -f "${DETECTED_HOMEDIR}/dsac_branch" ]]; then
        DSAC_BRANCH=$(cat "${DETECTED_HOMEDIR}/dsac_branch")
    fi

    if [[ ! $DSAC_BRANCH ]]; then
        DSAC_BRANCH="origin/master"
    fi
    
    local QUESTION
    QUESTION="Would you like to update DockSTARTer App Config to ${DSAC_BRANCH} now?"
    info "${QUESTION}"
    local YN
    while true; do
        if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]]; then
            info "Travis will not run this."
            return
        elif [[ ${PROMPT:-} == "menu" ]]; then
            local ANSWER
            set +e
            ANSWER=$(
                whiptail --fb --clear --title "DockSTARTer" --yesno "${QUESTION}" 0 0 3>&1 1>&2 2>&3
                echo $?
            )
            set -e
            if [[ ${ANSWER} == 0 ]]; then
                YN=Y
            else
                YN=N
            fi
        else
            read -rp "[Yn]" YN
        fi
        case ${YN} in
            [Yy]*)
                info "Updating DockSTARTer App Config."
                cd "${SCRIPTPATH}/.dsac" || fatal "Failed to change to ${SCRIPTPATH}/.dsac directory."
                git fetch > /dev/null 2>&1 || fatal "Failed to fetch recent changes from git."
                git reset --hard "${DSAC_BRANCH}" > /dev/null 2>&1 || fatal "Failed to reset to ${DSAC_BRANCH}."
                git pull > /dev/null 2>&1 || fatal "Failed to pull recent changes from git."
                git for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D > /dev/null 2>&1 || true
                info "Copying DockSTARTer App Config to DockSTARTer"
                find "${DETECTED_DSACDIR}/.scripts/" -type f -iname "*.sh" -exec chmod +x {} \;
                cp -rp "${DETECTED_DSACDIR}/.scripts/." "${DETECTED_HOMEDIR}/.docker/.scripts/"
                info "Injecting DockSTARTer App Config code into DockSTARTer"
                break
                ;;
            [Nn]*)
                info "DockSTARTer App Config will not be updated."
                return 1
                ;;
            *)
                error "Please answer yes or no."
                ;;
        esac
    done
    
    run_script 'dsac_run_inject'
}

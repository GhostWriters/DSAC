#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_quick_setup() {
    local QSCOPTS
    QSCOPTS=()
    QSCOPTS+=("TV Series & Movies" "Configuration for handling TV Series and Movies" "on")
    QSCOPTS+=("Music" "Configuration for handling Music" "on")
    QSCOPTS+=("Books & Comics" "Configuration for handling Books and Comics" "on")

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        local SELECTEDCONFIGS
        SELECTEDCONFIGS=$(whiptail --fb --clear --title "DockSTARTer App Config" --separate-output --checklist 'Choose which configuration(s) you want to have setup:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.\nSee the DSAC Wiki for more information about each option' 0 0 0 "${QSCOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        if [[ ${SELECTEDCONFIGS} == "Cancel" ]]; then
            return 1
        else
            local QUICK_SETUP_YML
            QUICK_SETUP_YML="${DETECTED_DSACDIR}/.data/quick_setup.yml"
            local CONFIGURE_APPS_YML
            CONFIGURE_APPS_YML="${DETECTED_DSACDIR}/.data/configure_apps.yml"

            info "Generating configure_apps.yml file."
            echo "" > "${CONFIGURE_APPS_YML}"

            while IFS= read -r line; do
                local CONFIGNAME
                CONFIGNAME=${line}
                debug "CONFIGNAME=${CONFIGNAME}"
                case "${CONFIGNAME}" in
                    "TV Series & Movies")
                        while IFS= read -r entry; do
                            yq-go w -i "${CONFIGURE_APPS_YML}" "managers.series[+]" "${entry}"
                        done < <(yq-go r "${QUICK_SETUP_YML}" "managers.series" | awk '{gsub("- ",""); print}')
                        while IFS= read -r entry; do
                            yq-go w -i "${CONFIGURE_APPS_YML}" "managers.movies[+]" "${entry}"
                        done < <(yq-go r "${QUICK_SETUP_YML}" "managers.movies" | awk '{gsub("- ",""); print}')
                        ;;
                    "Books & Comics")
                        while IFS= read -r entry; do
                            yq-go w -i "${CONFIGURE_APPS_YML}" "managers.books[+]" "${entry}"
                        done < <(yq-go r "${QUICK_SETUP_YML}" "managers.books" | awk '{gsub("- ",""); print}')
                        while IFS= read -r entry; do
                            yq-go w -i "${CONFIGURE_APPS_YML}" "managers.comics[+]" "${entry}"
                        done < <(yq-go r "${QUICK_SETUP_YML}" "managers.comics" | awk '{gsub("- ",""); print}')
                        ;;
                    "Music")
                        while IFS= read -r entry; do
                            yq-go w -i "${CONFIGURE_APPS_YML}" "managers.music[+]" "${entry}"
                        done < <(yq-go r "${QUICK_SETUP_YML}" "managers.music" | awk '{gsub("- ",""); print}')
                        ;;
                    *)
                        warn "${CONFIGNAME} not supported"
                        ;;
                esac
            done < <(echo "${SELECTEDCONFIGS}")

            while IFS= read -r entry; do
                yq-go w -i "${CONFIGURE_APPS_YML}" "${entry}[+]" "$(yq-go r "${QUICK_SETUP_YML}" "${entry}" | awk '{gsub("- ",""); print}')"
            done < <(yq-go r --printMode p "${QUICK_SETUP_YML}" "downloaders.*")

            while IFS= read -r entry; do
                yq-go w -i "${CONFIGURE_APPS_YML}" "indexers[+]" "$(yq-go r "${QUICK_SETUP_YML}" "${entry}" | awk '{gsub("- ",""); print}')"
            done < <(yq-go r --printMode p "${QUICK_SETUP_YML}" "indexers.*")

            info "Generation of configure_apps.yml complete."

            run_script 'run_dockstarter' install
            run_script 'run_dockstarter' install-dependecies
            run_script 'run_dockstarter' apps
            run_script 'run_dockstarter' compose
            run_script 'run_dockstarter' backup
            run_script 'configure_supported_apps'
        fi
    fi
}

test_menu_quick_setup() {
    warn "CI does not test menu_main."
}

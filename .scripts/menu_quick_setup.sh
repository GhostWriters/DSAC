#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_quick_setup() {
    local QSCOPTS
    QSCOPTS=()
    QSCOPTS+=("TV Series & Movies" "Configuration for handling TV Series and Movies" "on")
    QSCOPTS+=("Music" "Configuration for handling Music" "on")
    QSCOPTS+=("Books & Comics" "Configuration for handling Books" "on")

    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        local SELECTEDAPPS
        SELECTEDAPPS=$(whiptail --fb --clear --title "DockSTARTer App Config" --separate-output --checklist 'Choose which configuration(s) you want to have setup:\n Use [up], [down], and [space] to select apps, and [tab] to switch to the buttons at the bottom.\nSee the DSAC Wiki for more information about each option' 0 0 0 "${QSCOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
        if [[ ${SELECTEDAPPS} == "Cancel" ]]; then
            return 1
        else
            local CONFIGJSON
            CONFIGJSON="{}"
            info "Generating configure_apps.json file."
            echo "" > "${DETECTED_DSACDIR}/.data/configure_apps.json"
            while IFS= read -r line; do
                local CONFIGNAME
                CONFIGNAME=${line}
                debug "CONFIGNAME=${CONFIGNAME}"
                case "${CONFIGNAME}" in
                    "TV Series & Movies")
                        VALUES=$(jq ".managers.series" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
                        CONFIGJSON=$(jq ".managers.series = ${VALUES}" <<< "${CONFIGJSON}")
                        VALUES=$(jq ".managers.movies" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
                        CONFIGJSON=$(jq ".managers.movies = ${VALUES}" <<< "${CONFIGJSON}")
                        ;;
                    "Books & Comics")
                        VALUES=$(jq ".managers.books" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
                        CONFIGJSON=$(jq ".managers.books = ${VALUES}" <<< "${CONFIGJSON}")
                        VALUES=$(jq ".managers.comics" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
                        CONFIGJSON=$(jq ".managers.comics = ${VALUES}" <<< "${CONFIGJSON}")
                        ;;
                    "Music")
                        VALUES=$(jq ".managers.music" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
                        CONFIGJSON=$(jq ".managers.music = ${VALUES}" <<< "${CONFIGJSON}")
                        ;;
                    *)
                        warn "${CONFIGNAME} not supported"
                        ;;
                esac
            done < <(echo "${SELECTEDAPPS}")
            VALUES=$(jq ".downloaders" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
            CONFIGJSON=$(jq ".downloaders = ${VALUES}" <<< "${CONFIGJSON}")
            VALUES=$(jq ".indexers" "${DETECTED_DSACDIR}/.data/quick_setup_apps.json")
            CONFIGJSON=$(jq ".indexers = ${VALUES}" <<< "${CONFIGJSON}")

            echo "${CONFIGJSON}" > "${DETECTED_DSACDIR}/.data/configure_apps.json"
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

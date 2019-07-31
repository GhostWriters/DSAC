#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTS
    MAINOPTS=()
    MAINOPTS+=("Quick Setup Configurations " "= Select one or many pre-configured server types; uses DockSTARTer")
    MAINOPTS+=("Custom Setup " "= Full user input with no pre-selected apps; uses DockSTARTer")
    MAINOPTS+=("Configure Existing Containers " "= DSAC will detect and configure supported apps in your Docker Containers")
    MAINOPTS+=("Install/Update DockSTARTer " "= DSAC will Install/Update DockSTARTer for you")

    local MAINCHOICE
    if [[ ${CI:-} == true ]]; then
        MAINCHOICE="Cancel"
    else
        MAINCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config (DSAC)" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${MAINOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${MAINCHOICE}" in
        "Quick Setup Configurations ")
            run_script 'menu_quick_setup' || run_script 'menu_main'
            run_script 'run_dockstarter' install
            run_script 'run_dockstarter' install-dependecies
            run_script 'run_dockstarter' apps
            run_script 'run_dockstarter' compose
            run_script 'run_dockstarter' backup
            run_script 'configure_apps'
            ;;
        "Custom Setup ")
            run_script 'run_dockstarter' install
            run_script 'run_dockstarter' install-dependecies
            run_script 'read_manifest'
            run_script 'menu_custom_app_select' || run_script 'menu_main'
            run_script 'run_dockstarter' compose
            run_script 'run_dockstarter' backup
            info "Generating configure_apps.json file."
            cp "${SCRIPTPATH}/.data/supported_apps.json" "${SCRIPTPATH}/.data/configure_apps.json"
            info "Generation of configure_apps.json complete."
            run_script 'configure_apps'
            ;;
        "Configure Existing Containers ")
            info "Generating configure_apps.json file."
            cp "${SCRIPTPATH}/.data/supported_apps.json" "${SCRIPTPATH}/.data/configure_apps.json"
            info "Generation of configure_apps.json complete."
            run_script 'configure_apps'
            ;;
        "Install/Update DockSTARTer ")
            run_script 'run_dockstarter' install || run_script 'menu_main'
            ;;
        "Update DSAC ")
            run_script 'update_self' || run_script 'menu_main'
            ;;
        "Cancel")
            notice "Exiting DockSTARTer App Config."
            return
            ;;
        *)
            error "Invalid DSAC Menu Option"
            ;;
    esac
}

test_menu_main() {
    warn "Travis does not test menu_main."
}

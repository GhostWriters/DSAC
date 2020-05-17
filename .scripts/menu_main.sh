#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTS
    MAINOPTS=()
    MAINOPTS+=("Quick Setup Configurations " "= Select one or many pre-configured server types; uses DockSTARTer")
    MAINOPTS+=("Custom Setup " "= Full user input with no pre-selected apps; uses DockSTARTer")
    MAINOPTS+=("Configure Existing Containers " "= DSAC will detect and configure supported apps in your Docker Containers")

    local MAINCHOICE
    if [[ ${CI:-} == true ]]; then
        MAINCHOICE="Cancel"
    else
        MAINCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config (DSAC)" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${MAINOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${MAINCHOICE}" in
        "Quick Setup Configurations ")
            run_script 'menu_quick_setup' || run_script 'menu_main'
            ;;
        "Custom Setup ")
            run_script 'menu_custom_app_select' || run_script 'menu_main'
            ;;
        "Configure Existing Containers ")
            info "Generating configure_apps.yml file."
            cp "${SCRIPTPATH}/.data/supported_apps.yml" "${SCRIPTPATH}/.data/configure_apps.yml"
            info "Generation of configure_apps.yml complete."
            run_script 'configure_supported_apps'
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
    warn "CI does not test menu_main."
}

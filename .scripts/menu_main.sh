#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTS
    MAINOPTS=()
    # TODO: Revisit - MAINOPTS+=("Quick Setup " "= Little user input with pre-selected apps; uses DockSTARTer")
    # TODO: Revisit - MAINOPTS+=("Custom Setup " "= Full user input with no pre-selected apps")
    MAINOPTS+=("Configure Existing Containers " "= DSAC will detect and configure supported apps")

    local MAINCHOICE
    MAINCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${MAINOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${MAINCHOICE}" in
        "Quick Setup ")
            #run_script 'read_manifest'
            #run_script 'run_install_dockstarter'
            run_script 'run_preconfigured_apps'
            #TODO: run_script 'configure_apps'
            #TODO: run_script 'run_dockstarter'
            ;;
        "Custom Setup ")
            #run_script 'read_manifest'
            run_script 'menu_app_select'
            #TODO: run_script 'configure_apps'
            ;;
        "Configure Existing Containers ")
            run_script 'configure_apps'
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid DSAC Option"
            ;;
    esac
}

test_menu_main() {
    warning "Travis does not test menu_main."
}

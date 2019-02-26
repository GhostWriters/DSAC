#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_main() {
    local MAINOPTS
    MAINOPTS=()
    MAINOPTS+=("Quick Setup " "= Little user input with pre-selected apps")
    MAINOPTS+=("Full Setup " "= Full user input with no pre-selected apps")

    local MAINCHOICE
    MAINCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${MAINOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${MAINCHOICE}" in
        "Quick Setup ")
            run_script 'read_manifest'
            # TODO: pre-configured apps
            # TODO: user inputs, as needed
            ;;
        "Full Setup ")
            run_script 'read_manifest'
            run_script 'menu_app_select'
            # TODO: user inputs, as needed
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

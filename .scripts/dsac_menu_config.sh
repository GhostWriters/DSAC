#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_menu_config() {
    local DSAC_CONFIGOPTS
    DSAC_CONFIGOPTS=()
    DSAC_CONFIGOPTS+=("Quick Setup " "= Little user input with pre-selected apps")
    DSAC_CONFIGOPTS+=("Full Setup " "= Full user input with no pre-selected apps")

    local DSAC_CONFIGCHOICE
    CONFIGCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config" --menu "What would you like to do?" 0 0 0 "${DSAC_CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${DSAC_CONFIGCHOICE}" in
        "Quick Setup ")
            # TODO: pre-configured apps
            # TODO: user inputs, as needed
            error "${CONFIGCHOICE} not yet available"
            ;;
        "Full Setup ")
            # TODO: run_script 'dsac_menu_app_select'
            # TODO: user inputs, as needed
            error "${CONFIGCHOICE} not yet available"
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

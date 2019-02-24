#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_menu_config() {
    local CONFIGOPTS
    CONFIGOPTS=()
    CONFIGOPTS+=("Quick Setup " "- Little user input with pre-selected apps")
    CONFIGOPTS+=("Full Setup " "- Full user input with no pre-selected apps")

    local CONFIGCHOICE
    CONFIGCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config" --menu "What would you like to do?" 0 0 0 "${CONFIGOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")

    case "${CONFIGCHOICE}" in
        "Quick Setup ")
            # TODO: pre-configured apps
            # TODO: user inputs, as needed
            warning "${CONFIGCHOICE} not yet available"
            info "Returning to Main Menu."
            return 1
            ;;
        "Full Setup ")
            # TODO: run_script 'dsac_menu_app_select'
            # TODO: user inputs, as needed
            warning "${CONFIGCHOICE} not yet available"
            info "Returning to Main Menu."
            return 1
            ;;
        "Cancel")
            info "Returning to Main Menu."
            return 1
            ;;
        *)
            error "Invalid Option"
            ;;
    esac
}

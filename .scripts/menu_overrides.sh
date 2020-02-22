#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

menu_overrides() {
    local OVERRIDESOPTS
    OVERRIDESOPTS=()
    OVERRIDESOPTS+=("Compile " "= Validate files and Compile Docker Overrides file")
    OVERRIDESOPTS+=("Validate " "= Validate files")

    local OVERRIDESCHOICE
    if [[ ${CI:-} == true ]]; then
        OVERRIDESCHOICE="Cancel"
    else
        OVERRIDESCHOICE=$(whiptail --fb --clear --title "DockSTARTer App Config (DSAC)" --cancel-button "Exit" --menu "What would you like to do?" 0 0 0 "${OVERRIDESOPTS[@]}" 3>&1 1>&2 2>&3 || echo "Cancel")
    fi

    case "${MAINCHOICE}" in
        "Compile ")
            run_script 'docker_overrides_compile'
            ;;
        "Validate ")
            run_script 'docker_overrides_validate'
            ;;
        "Cancel")
            return 1
            ;;
        *)
            error "Invalid DSAC Menu Option"
            ;;
    esac
}

test_menu_overrides() {
    warn "CI does not test menu_overrides."
}

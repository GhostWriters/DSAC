#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

inject_main() {
    file="${SCRIPTPATH}/main.sh"
    line_to_add_after='fatal "Failed to clone DockSTARTer repo to ${DETECTED_HOMEDIR}/.docker location."'
    line_number=$(grep -n ${line_to_add_after})
    #Add these backwards so they come out in the right order instead of chaning the line number

    lines_to_add="run_script 'dsac/run_inject'"
    awk -v n=$line_number insert="${line_to_add}" '{print} NR == n {print insert}' $file

    lines_to_add='info "Configuring DockSTARTer to support DockSTARTer App Config."'
    awk -v n=$line_number insert="${line_to_add}" '{print} NR == n {print insert}' $file

    lines_to_add='git clone https://github.com/GhostWriters/DSAC "${DETECTED_HOMEDIR}/.docker/.dsac" || fatal "Failed to clone DockSTARTer App Config repo to ${DETECTED_HOMEDIR}/.docker location."'
    awk -v n=$line_number insert="${line_to_add}" '{print} NR == n {print insert}'

    line_to_add='warning "Attempting to clone DockSTARTer App Config repo to ${DETECTED_HOMEDIR}/.docker/.dsac location."\n'
    awk -v n=$line_number insert="${line_to_add}" '{print} NR == n {print insert}' $file
}

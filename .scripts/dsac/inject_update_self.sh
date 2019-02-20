#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

inject_update_self() {
    file="${SCRIPTPATH}/.scripts/update_self.sh"
    line_to_add_after='chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."'
    line_number=$(grep -n ${line_to_add_after})
    #Add these backwards so they come out in the right order instead of chaning the line number

    lines_to_add="run_script 'dsac/update'"
    awk -v n=$line_number insert="${line_to_add}" '{print} NR == n {print insert}' $file
}

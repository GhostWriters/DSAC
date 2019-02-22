#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_inject_main() {
    local file
    file="main.sh"
    local file_path
    file_path="${DETECTED_HOMEDIR}/.docker/${file}"
    
    if [[ $(grep -c "# DSAC injected code" $file_path) = 0 ]]; then
        info "Injecting code into DockSTARTer ${file}"

        line_to_add_after="readonly DETECTED_HOMEDIR=\$(eval echo \"~\${DETECTED_UNAME}\" 2> /dev/null || true)"
        line_number=$(($(grep -n "${line_to_add_after}" $file_path | sed 's/^\([0-9]\+\):.*$/\1/')+1))

        lines_to_add=(
            "# DSAC injected code"
            "# DSAC Information"
            "readonly DETECTED_DSACDIR=\$(eval echo \"~\${DETECTED_UNAME}/.docker/.dsac\" 2> /dev/null || true)"
            "# /DSAC injected code"
        )

        for i in ${!lines_to_add[@]}; do
            line_to_add=${lines_to_add[$i]}
            sed -i "${line_number}i $line_to_add" $file_path
            line_number=$((line_number+1))
        done

        line_to_add_after="Failed to clone DockSTARTer repo to \${DETECTED_HOMEDIR}/.docker location."
        line_number=$(($(grep -n "${line_to_add_after}" $file_path | sed 's/^\([0-9]\+\):.*$/\1/')+1))

        lines_to_add=(
            "            # DSAC injected code"
            "            warning \"Attempting to clone DockSTARTer App Config repo to \${DETECTED_HOMEDIR}/.docker/.dsac location.\""
            "            git clone https://github.com/GhostWriters/DSAC \"\${DETECTED_HOMEDIR}/.docker/.dsac\" || fatal \"Failed to clone DockSTARTer App Config repo to \${DETECTED_HOMEDIR}/.docker location.\""
            "            info \"Configuring DockSTARTer to support DockSTARTer App Config.\""
            "            run_script 'dsac_run_inject'"
            "            # /DSAC injected code"
        )

        for i in ${!lines_to_add[@]}; do
            line_to_add=${lines_to_add[$i]}
            sed -i "${line_number}i $line_to_add" $file_path
            line_number=$((line_number+1))
        done
    else
        warning "Code already injected into DockSTARTer ${file}"
    fi
}

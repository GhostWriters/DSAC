#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

inject_ds_menu_config() {
    local file
    file="menu_config.sh"
    local file_path
    file_path="${DETECTED_HOMEDIR}/.docker/.scripts/${file}"

    if [[ $(grep -c "# DSAC injected code" $file_path) = 0 ]]; then
        info "Injecting code into DockSTARTer ${file}"
        line_to_add_after="CONFIGOPTS=()"
        line_number=$(($(grep -n "${line_to_add_after}" $file_path | sed 's/^\([0-9]\+\):.*$/\1/')+1))

        lines_to_add=(
            "\    # DSAC injected code"
            "\    CONFIGOPTS+=(\"DSAC Setup \" \"\")"
            "\    # /DSAC injected code"
        )

        for i in ${!lines_to_add[@]}; do
            line_to_add=${lines_to_add[$i]}
            sed -i "${line_number}i $line_to_add" $file_path
            line_number=$((line_number+1))
        done
        
        line_to_add_before="\"Full Setup \")"
        line_number=$(grep -n "${line_to_add_before}" $file_path | sed 's/^\([0-9]\+\):.*$/\1/')

        lines_to_add=(
            "\        # DSAC injected code"
            "\        \"DSAC Setup \")"
            "\            run_script 'dsac_menu_config'"
            "\            ;;"
            "\        # /DSAC injected code"
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

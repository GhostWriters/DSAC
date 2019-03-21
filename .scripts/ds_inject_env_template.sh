#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ds_inject_env_template() {
    local file
    file=".env.template"
    local file_path
    file_path="${DETECTEDDSDIR}/compose/${file}"

    local APPNAME
    APPNAME=${1}
    local SET_VAR
    SET_VAR=${2}
    local SET_VAL
    SET_VAL=${3}
    if grep -q "^${SET_VAR}=" "${file_path}"; then
        run_script 'ds_env_template_set' "${SET_VAR}" "${SET_VAL}"
    else
        line_number=$(($(grep -n "${APPNAME}" $file_path | tail -1 | sed 's/^\([0-9]\+\):.*$/\1/')+1))
        line_to_add="${SET_VAR}=${SET_VAL}"
        sed -i "${line_number}i $line_to_add" $file_path
    fi
}

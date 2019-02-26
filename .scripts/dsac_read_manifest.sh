#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_read_manifest() {
    local MANIFEST_FILE
    MANIFEST_FILE="${DETECTED_DSACDIR}/dsac_manifest.csv"
    local DSAC_APPS_FILE
    DSAC_APPS_FILE="${DETECTED_DSACDIR}/dsac_apps"
    touch ${DSAC_APPS_FILE}

    local CSV_HEADERS
    CSV_HEADERS=$(awk '{if (NR==1) { gsub("\"",""); print toupper($0)}}' "${MANIFEST_FILE}")
    local HEADERS
    IFS='|' read -r -a HEADERS <<< "$CSV_HEADERS"

    local DSAC_APPNAME
    DSAC_APPNAME=""
    while IFS= read -r line; do
        IFS='|' read -r -a ROW <<< $line
        for index in "${!ROW[@]}"
        do
            if [[ "${HEADERS[$index]}" = "${HEADERS[0]}" ]]; then
                DSAC_APPNAME=${ROW[$index]//\"/}
                echo "" >> $DSAC_APPS_FILE
                echo "### ${DSAC_APPNAME}" >> $DSAC_APPS_FILE
            else
                echo "${DSAC_APPNAME}_${HEADERS[$index]}=${ROW[$index]}" >> $DSAC_APPS_FILE
            fi
        done

    done < <(awk '{if (NR!=1) { print toupper($0) }}' "${MANIFEST_FILE}")
}

IFS=$'\n\t'

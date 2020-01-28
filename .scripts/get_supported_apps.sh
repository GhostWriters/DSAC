
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

get_supported_apps() {
    local DSAC_APPS_FILE
    DSAC_APPS_FILE="${DETECTED_DSACDIR}/.data/.env"
    if [[ -f ${DSAC_APPS_FILE} ]]; then
        rm "${DSAC_APPS_FILE}"
    fi
    touch "${DSAC_APPS_FILE}"

    mapfile -t app_types < <(jq ".[]" "${DETECTED_DSACDIR}/.data/supported_apps.json" | jq 'keys[]')
    for app_type_index in "${!app_types[@]}"; do
        app_type=${app_types[${app_type_index}]//\"/}

        mapfile -t app_categories < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/supported_apps.json" | jq 'keys[]')
        #shellcheck disable=SC2154
        for app_category_index in "${!app_categories[@]}"; do
            app_category=${app_categories[${app_category_index}]//\"/}
            if [[ ${app_type} == "indexers" || ${app_type} == "others" ]]; then
                mapfile -t apps < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/supported_apps.json" | jq 'values[]')
                info "- ${app_type}"
            else
                mapfile -t apps < <(jq ".${app_type}.${app_category}" "${DETECTED_DSACDIR}/.data/supported_apps.json" | jq 'values[]')
                info "- ${app_category} ${app_type}"
            fi
            for app_index in "${!apps[@]}"; do
                app_name=${apps[${app_index}]//\"/}
                echo "${app_name}_DSAC_SUPPORTED=true" >> "$DSAC_APPS_FILE"
            done
        done
    done
}

test_get_supported_apps() {
    warn "Test not configured yet."
}

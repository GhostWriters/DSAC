#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_dockstarter() {
    local ACTION=${1:-}

    if [[ ${ACTION} == "install" ]]; then
        if [[ ! -d ${DETECTED_HOMEDIR}/.docker/.git ]]; then
            notice "Installing DockSTARTer..."
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_DSDIR}"
            bash ${DETECTED_DSDIR}/main.sh -vi
        else
            notice "Updating DockSTARTer..."
            (ds -u)
        fi
    elif [[ ${ACTION} == "install-dependecies" ]]; then
        (ds -i)
    elif [[ ${ACTION} == "backup" ]]; then
        (ds -b "${2:-med}")
    elif [[ ${ACTION} == "compose" ]]; then
        local WAIT_TIME=1
        local i=0
        #shellcheck disable=SC1003
        local indicators=('\' '|' '/' '-')
        typeset -A containers_check
        (ds -c up)
        notice "Waiting for containers to be running for ${WAIT_TIME} minute(s)..."
        while true; do
            local not_ready="false"
            modulo=$((i % 4))
            echo -en "\r${indicators[${modulo}]}"
            while IFS= read -r line; do
                local container_id=${line}
                if [[ ${containers_check[${container_id}]+true} != "true" ]]; then
                    containers_check[${container_id}]=$(docker inspect --format='{{.State.StartedAt}}' "${container_id}" | xargs date +%s%3N -d)
                fi
                if [[ ${containers_check[${container_id}]} != "ready" ]]; then
                    NOW=$(date +%s%3N)
                    TIME_DIFF=$((NOW - containers_check[${container_id}]))
                    TIME_DIFF=$((TIME_DIFF / 60000))
                    if [[ ${TIME_DIFF} -ge 1 ]]; then
                        containers_check[${container_id}]="ready"
                    else
                        not_ready="true"
                    fi
                fi
            done < <(docker ps -q)
            if [[ ${not_ready} == "false" ]]; then
                info "All containers appear to be ready!"
                break
            fi
            sleep 1s
            i=$((i + 1))
        done
    elif [[ ${ACTION} == "apps" ]]; then
        notice "Updating DS .env"
        (ds -e)
        notice "Adding apps to DS"
        mapfile -t app_types < <(jq 'keys[]' "${DETECTED_DSACDIR}/.data/configure_apps.json")
        for app_type_index in "${!app_types[@]}"; do
            app_type=${app_types[${app_type_index}]//\"/}
            info "- ${app_type}"
            mapfile -t app_categories < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'keys[]')
            #shellcheck disable=SC2154
            if [[ ${app_type} == "indexers" || ${app_type} == "others" ]]; then
                mapfile -t apps < <(jq ".${app_type}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'values[]')
                for app_index in "${!apps[@]}"; do
                    app=${apps[${app_index}]^^}
                    app=${app//\"}
                    debug "    - ${app}"
                    debug "      Creating app vars"
                    (ds -a "${app}")
                    debug "      Setting env"
                    run_script 'ds_env_set' "${app}_ENABLED" true
                done
            else
                for app_category_index in "${!app_categories[@]}"; do
                    app_category=${app_categories[${app_category_index}]//\"/}
                    info "  - ${app_category}"
                    mapfile -t apps < <(jq ".${app_type}.${app_category}" "${DETECTED_DSACDIR}/.data/configure_apps.json" | jq 'values[]')
                    for app_index in "${!apps[@]}"; do
                        app=${apps[${app_index}]^^}
                        app=${app//\"}
                        debug "    - ${app}"
                        debug "      Creating app vars"
                        (ds -a ${app})
                        debug "      Setting env"
                        run_script 'ds_env_set' "${app}_ENABLED" true
                    done
                done
            fi
        done
        notice "Adding apps to DS completed"
    fi
}

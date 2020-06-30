#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_dockstarter() {
    local ACTION=${1:-}

    if [[ ${ACTION} == "install" ]]; then
        if [[ ! -d ${DETECTED_HOMEDIR}/.docker/.git ]]; then
            notice "Installing DockSTARTer..."
            git clone https://github.com/GhostWriters/DockSTARTer "${DETECTED_DSDIR}"
            bash "${DETECTED_DSDIR}/main.sh" -vi
        else
            (ds -f -u)
        fi
    elif [[ ${ACTION} == "install-dependecies" ]]; then
        (ds -f -i)
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
                    TIME_DIFF=$((NOW - containers_check[\$container_id]))
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
        mapfile -t APP_TYPES < <(yq-go r --printMode p "${DETECTED_DSACDIR}/.data/configure_apps.yml" "*")
        for APP_TYPE in "${APP_TYPES[@]}"; do
            #shellcheck disable=SC2154
            if [[ ${APP_TYPE} == "indexers" || ${APP_TYPE} == "others" ]]; then
                info "Media ${APP_TYPE}"
                mapfile -t APPS < <(yq-go r "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}" | awk '{gsub("- ",""); print}')
                for APPNAME in "${APPS[@]}"; do
                    APPNAME=${APPNAME^}
                    debug "${APPNAME}"
                    debug "Creating app vars"
                    (ds -a "${APPNAME^^}")
                    debug "Setting env"
                    (ds --env-set="${APPNAME^^}_ENABLED",true)
                done
            else
                mapfile -t APP_CATEGORIES < <(yq-go r --printMode p "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}.*")
                for APP_CATEGORY in "${APP_CATEGORIES[@]}"; do
                    APP_CATEGORY=${APP_CATEGORY//${APP_TYPE}./}
                    info "Media ${APP_TYPE} - ${APP_CATEGORY}"
                    mapfile -t APPS < <(yq-go r "${DETECTED_DSACDIR}/.data/configure_apps.yml" "${APP_TYPE}.${APP_CATEGORY}" | awk '{gsub("- ",""); print}')
                    for APPNAME in "${APPS[@]}"; do
                        APPNAME=${APPNAME^}
                        debug "${APPNAME}"
                        debug "Creating app vars"
                        (ds -a "${APPNAME^^}")
                        debug "Setting env"
                        (ds --env-set="${APPNAME^^}_ENABLED",true)
                    done
                done
            fi
        done
        notice "Adding apps to DS completed"
    fi
}

test_run_dockstarter() {
    warn "Test not configured yet."
}

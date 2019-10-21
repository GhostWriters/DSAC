#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2034
typeset -A containers
# shellcheck disable=SC2034
typeset -A API_KEYS

configure_supported_apps() {
    notice "Configuring supported applications"
    run_script 'get_docker_containers'
    run_script 'get_api_keys'
    run_script 'configure_applications' 'downloaders'
    run_script 'configure_applications' 'managers'
    run_script 'configure_applications' 'indexers'
    notice "Configuration completed!"
}

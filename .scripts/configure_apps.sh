#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

typeset -A containers
typeset -A API_KEYS

configure_apps() {
    notice "Configuring supported applications"
    run_script 'get_docker_containers'
    run_script 'get_api_keys'
    run_script 'configure_containers' 'downloaders'
    run_script 'configure_containers' 'managers'
    run_script 'configure_containers' 'indexers'
    notice "Configuration completed!"
}

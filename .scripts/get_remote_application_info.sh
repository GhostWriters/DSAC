#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

typeset -A containers
typeset -A API_KEYS

get_remote_application_info() {
    notice "Getting information"
    run_script 'get_docker_containers'
    # shellcheck disable=SC2154
    for container_name in "${!containers[@]}"; do
        info "- ${container_name}"
        case "${container_name}" in
            "radarr" | "sonarr" | "lidarr")
                if run_script 'question_prompt' "${PROMPT:-}" N "${container_name^} can be connected to a remote instance of Hydra or Jackett.\\n\\nDo you want to configure ${container_name^} to connect to one of these?"; then
                    exit #TODO: Complete this
                fi
                ;;
            *)
                exit  #TODO: Complete this
                ;;
        esac
    done
    notice "Connecting supported applications to supported remote applications"
    run_script 'get_api_keys'
    run_script 'configure_applications' 'downloaders'
    run_script 'configure_applications' 'managers'
    run_script 'configure_applications' 'indexers'
    notice "Configuration completed!"
}

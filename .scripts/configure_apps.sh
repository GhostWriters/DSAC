#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# shellcheck disable=SC2034
typeset -A containers
# shellcheck disable=SC2034
typeset -A containers_image
# shellcheck disable=SC2034
typeset -A containers_config_path
# shellcheck disable=SC2034
typeset -A containers_ports
# shellcheck disable=SC2034
typeset -A API_KEYS

configure_apps() {
    info "Configuring supported applications"
    run_script 'get_docker_containers'
    run_script 'get_api_keys'
    # TODO: run_script 'configure_usenet_downloader'
    run_script 'configure_torrent_downloader'
    run_script 'configure_movies_manager'
    run_script 'configure_series_manager'
    run_script 'configure_music_manager'
    # TODO: run_script 'configure_books_manager'
    # TODO: run_script 'configure_comics_manager'
    # TODO: run_script 'configure_media_server'
    info "Configuration completed!"
}

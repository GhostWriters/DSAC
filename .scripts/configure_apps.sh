#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

typeset -A containers
typeset -A containers_image
typeset -A containers_config_path
typeset -A containers_ports
typeset -A API_KEYS

configure_apps() {
    run_script 'get_docker_containers'
    run_script 'get_api_keys'
    # TODO: run_script 'configure_usenet_downloader'
    # TODO: run_script 'configure_torrent_downloader'
    run_script 'configure_movies_manager'
    # TODO: run_script 'configure_series_manager'
    # TODO: run_script 'configure_books_manager'
    # TODO: run_script 'configure_comics_manager'
    # TODO: run_script 'configure_media_server'
}

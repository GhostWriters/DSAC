#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

typeset -A containers
typeset -A API_KEYS

configure_apps() {
    info "Configuring supported applications"
    run_script 'get_docker_containers'
    run_script 'get_api_keys'
    run_script 'configure_usenet_downloader'
    run_script 'configure_torrent_downloader'
    run_script 'configure_movies_manager'
    run_script 'configure_series_manager'
    run_script 'configure_music_manager'
    run_script 'configure_books_manager'
    #TODO: run_script 'configure_comics_manager'
    #TODO: run_script 'configure_media_server'
    run_script 'configure_subtitles_manager'
    info "Configuration completed!"
}

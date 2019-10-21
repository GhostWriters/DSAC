#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

develop_reset() {
    if [[ -d .dsac ]]; then
        warning "Removing DSAC directory"
        sudo rm -r .dsac
    fi
    if [[ -d .docker ]]; then
        warning "Removing DS directory"
        sudo rm -r .docker
    fi
}

test_develop_reset() {
    warn "CI does not test this script"
}

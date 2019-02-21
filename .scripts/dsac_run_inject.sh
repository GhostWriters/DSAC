#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

dsac_run_inject() {
    run_script 'dsac_inject_main'
    run_script 'dsac_inject_update_self'
}

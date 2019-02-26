#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_ds_inject() {
    run_script 'inject_ds_main'
    run_script 'inject_ds_menu_config'
}

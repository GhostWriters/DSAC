#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_inject() {
    run_script 'inject_main'
}

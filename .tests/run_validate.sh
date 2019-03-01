#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

run_validate() {
    curl -fsSL https://raw.githubusercontent.com/nemchik/ShellSuite/master/shellsuite.sh -o shellsuite.sh
    bash shellsuite.sh -p "${DETECTED_DSACDIR}" -v "bashate" -f " -i E006"
    bash shellsuite.sh -p "${DETECTED_DSACDIR}" -v "shellcheck" -f " -x"
    bash shellsuite.sh -p "${DETECTED_DSACDIR}" -v "shfmt" -f " -s -i 4 -ci -sr -d"
    rm shellsuite.sh
}

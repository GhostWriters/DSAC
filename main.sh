#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage Information
#/ Usage: sudo dsac [OPTION]
#/ NOTE: dsac shortcut is only available after the first run of
#/       sudo bash ~/.dsac/main.sh
#/
#/ This is the main DockSTARTer App Config script.
#/ For regular usage you can run without providing any options.
#/
#/  -t --test <test_name>
#/      run tests to check the program
#/  -u --update
#/      update DockSTARTer to the latest stable commits
#/  -u --update <branch>
#/      update DockSTARTer to the latest commits from the specified branch
##/ -v --verbose
##/     verbose
#/  -x --debug
#/      debug
#/
usage() {
    grep '^#/' "${SCRIPTNAME}" | cut -c4- || echo "Failed to display usage information."
    exit
}

# Command Line Arguments
readonly ARGS=("$@")

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
fi

# Script Information
# https://stackoverflow.com/a/246128/1384186
get_scriptname() {
    local SOURCE
    local DIR
    SOURCE="${BASH_SOURCE[0]:-$0}" # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source
    while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
        DIR="$(cd -P "$(dirname "${SOURCE}")" > /dev/null && pwd)"
        SOURCE="$(readlink "${SOURCE}")"
        [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "${SOURCE}"
}
readonly SCRIPTNAME="$(get_scriptname)"
readonly SCRIPTPATH="$(cd -P "$(dirname "${SCRIPTNAME}")" > /dev/null && pwd)"

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# DS Information
readonly DETECTED_DSDIR=$(eval echo "~${DETECTED_UNAME}/.docker" 2> /dev/null || true)

# DSAC Information
readonly DETECTED_DSACDIR=$(eval echo "~${DETECTED_UNAME}/.dsac" 2> /dev/null || true)

# Other Information
readonly NIC=$(ip -o -4 route show to default | head -1 | awk '{print $5}')
readonly LOCAL_IP=$(ifconfig "${NIC}" | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*')

# Colors
# https://misc.flogisoft.com/bash/tip_colors_and_formatting
readonly BLU='\e[34m'
readonly GRN='\e[32m'
readonly RED='\e[31m'
readonly YLW='\e[33m'
readonly NC='\e[0m'

# Log Functions
readonly LOG_FILE="/tmp/dockstarterappconfig.log"
#Save current log if not empty and rotate logs
savelog -n -C -l -t "$LOG_FILE"
sudo chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${LOG_FILE}" > /dev/null 2>&1 || true # This line should always use sudo
log() {
    if [[ -v DEBUG && $DEBUG == 1 ]] || [[ -v VERBOSE && $VERBOSE == 1 ]] || [[ -v DEVMODE && $DEVMODE == 1 ]]; then
        echo -e "${NC}$(date +"%F %T") ${BLU}[LOG]${NC}        $*${NC}" | tee -a "${LOG_FILE}" >&2
    else
        echo -e "${NC}$(date +"%F %T") ${BLU}[LOG]${NC}        $*${NC}" | tee -a "${LOG_FILE}" > /dev/null
    fi
}
info() { echo -e "${NC}$(date +"%F %T") ${BLU}[INFO]${NC}       $*${NC}" | tee -a "${LOG_FILE}" >&2; }
warning() { echo -e "${NC}$(date +"%F %T") ${YLW}[WARNING]${NC}    $*${NC}" | tee -a "${LOG_FILE}" >&2; }
error() { echo -e "${NC}$(date +"%F %T") ${RED}[ERROR]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2; }
fatal() {
    echo -e "${NC}$(date +"%F %T") ${RED}[FATAL]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2
    exit 1
}
debug() {
    if [[ -v DEBUG && $DEBUG == 1 ]] || [[ -v VERBOSE && $VERBOSE == 1 ]] || [[ -v DEVMODE && $DEVMODE == 1 ]]; then
        echo -e "${NC}$(date +"%F %T") ${GRN}[DEBUG]${NC}      $*${NC}" | tee -a "${LOG_FILE}" >&2
    fi
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"
    shift
    if [[ -f ${DETECTED_DSACDIR}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${DETECTED_DSACDIR}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    else
        fatal "${DETECTED_DSACDIR}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"
    shift
    if [[ -f ${SCRIPTPATH}/.tests/${TESTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.tests/${TESTSNAME}.sh"
        ${TESTSNAME} "$@"
    else
        fatal "${SCRIPTPATH}/.tests/${TESTSNAME}.sh not found."
    fi
}

# Version functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! verlte "${1}" "${2}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Root Check
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as a standard user with sudo."
    fi
}

# Cleanup Function
cleanup() {
    if [[ ${SCRIPTPATH} == "${DETECTED_DSACDIR}" ]]; then
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "ds must be executable."
    fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == false ]]; then
        warning "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi
}
trap 'cleanup' 0 1 2 3 6 14 15

# Main Function
main() {
    # Arch Check
    readonly ARCH=$(uname -m)
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Terminal Check
    if [[ -n ${PS1:-} ]] || [[ ${-} == *"i"* ]]; then
        root_check
    fi
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]] && [[ -z ${ARGS[*]:-} ]]; then
        root_check
        if [[ ! -d ${DETECTED_DSACDIR}/.git ]]; then
            warning "Attempting to clone DockSTARTer App Config repo to ${DETECTED_DSACDIR} location."
            git clone https://github.com/GhostWriters/DSAC "${DETECTED_DSACDIR}" || fatal "Failed to clone DockSTARTer App Config repo to ${DETECTED_DSACDIR}/.dsac location."
            info "Performing first run install."
            (sudo bash "${DETECTED_DSACDIR}/main.sh" "-i") || fatal "Failed first run install, please reboot and try again."
            exit
        elif [[ ${SCRIPTPATH} != "${DETECTED_DSACDIR}" ]]; then
            (sudo bash "${DETECTED_DSACDIR}/main.sh" "-u") || true
            warning "Attempting to run DockSTARTer App Config from ${DETECTED_DSACDIR} location."
            (sudo bash "${DETECTED_DSACDIR}/main.sh") || true
            exit
        fi
    fi
    # Sudo Check
    if [[ ${EUID} != "0" ]]; then
        (sudo bash "${SCRIPTNAME:-}" "${ARGS[@]:-}") || true
        exit
    fi
    run_script 'symlink_dsac'
    # shellcheck source=/dev/null
    source "${SCRIPTPATH}/.scripts/cmdline.sh"
    cmdline "${ARGS[@]:-}"
    readonly PROMPT="menu"
    run_script 'menu_main'
}
main

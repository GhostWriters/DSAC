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
#/ -v --verbose
#/     verbose
#/  -x --debug
#/      debug
#/
usage() {
    grep --color=never -Po '^#/\K.*' "${BASH_SOURCE[0]:-$0}" || echo "Failed to display usage information."
    exit
}

# Command Line Arguments
readonly ARGS=("$@")
cmdline() {
    # http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local ARG=
    local LOCAL_ARGS
    for ARG; do
        local DELIM=""
        case "${ARG}" in
            #translate --gnu-long-options to -g (short options)
            --debug) LOCAL_ARGS="${LOCAL_ARGS:-}-x " ;;
            --force) LOCAL_ARGS="${LOCAL_ARGS:-}-f " ;;
            --help) LOCAL_ARGS="${LOCAL_ARGS:-}-h " ;;
            --install) LOCAL_ARGS="${LOCAL_ARGS:-}-i " ;;
            --test) LOCAL_ARGS="${LOCAL_ARGS:-}-t " ;;
            --update) LOCAL_ARGS="${LOCAL_ARGS:-}-u " ;;
            --verbose) LOCAL_ARGS="${LOCAL_ARGS:-}-v " ;;
            #pass through anything else
            *)
                [[ ${ARG:0:1} == "-" ]] || DELIM='"'
                LOCAL_ARGS="${LOCAL_ARGS:-}${DELIM}${ARG}${DELIM} "
                ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS:-}"

    while getopts ":dhit:u:vx" OPTION; do
        case ${OPTION} in
            d)
                readonly DEBUG=1
                ;;
            f)
                readonly FORCE=true
                ;;
            h)
                usage
                exit
                ;;
            i)
                readonly INSTALL=true
                ;;
            t)
                readonly TEST=${OPTARG}
                ;;
            u)
                readonly UPDATE=${OPTARG}
                ;;
            v)
                readonly VERBOSE=1
                ;;
            x)
                readonly DEBUG=1
                set -x
                ;;
            :)
                case ${OPTARG} in
                    u)
                        readonly UPDATE=true
                        ;;
                    *)
                        echo "${OPTARG} requires an option."
                        exit 1
                        ;;
                esac
                ;;
            *)
                usage
                exit
                ;;
        esac
    done
    return 0
}
cmdline "${ARGS[@]:-}"
if [[ -n ${DEBUG:-} ]] && [[ -n ${VERBOSE:-} ]]; then
    readonly TRACE=1
fi

# Github Token for Travis CI
if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == true ]]; then
    readonly GH_HEADER="Authorization: token ${GH_TOKEN}"
    export GH_HEADER
fi

# Script Information
# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself/246128#246128
get_scriptname() {
    # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source/35006505#35006505
    local SOURCE=${BASH_SOURCE[0]:-$0}
    while [[ -L ${SOURCE} ]]; do # resolve ${SOURCE} until the file is no longer a symlink
        local DIR
        DIR=$(cd -P "$(dirname "${SOURCE}")" > /dev/null 2>&1 && pwd)
        SOURCE=$(readlink "${SOURCE}")
        [[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if ${SOURCE} was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    echo "${SOURCE}"
}
readonly SCRIPTPATH=$(cd -P "$(dirname "$(get_scriptname)")" > /dev/null 2>&1 && pwd)
readonly SCRIPTNAME="${SCRIPTPATH}/$(basename "$(get_scriptname)")"

# User/Group Information
readonly DETECTED_PUID=${SUDO_UID:-$UID}
readonly DETECTED_UNAME=$(id -un "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_PGID=$(id -g "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_UGROUP=$(id -gn "${DETECTED_PUID}" 2> /dev/null || true)
readonly DETECTED_HOMEDIR=$(eval echo "~${DETECTED_UNAME}" 2> /dev/null || true)

# DS Information
readonly DETECTED_DSDIR=$(eval echo "~${DETECTED_UNAME}/.docker" 2> /dev/null || true)
export DETECTED_DSDIR

# DSAC Information
readonly DETECTED_DSACDIR=$(eval echo "~${DETECTED_UNAME}/.dsac" 2> /dev/null || true)

# Terminal Colors
if [[ ${CI:-} == true ]] || [[ -t 1 ]]; then
    readonly SCRIPTTERM=true
fi
tcolor() {
    if [[ -n ${SCRIPTTERM:-} ]]; then
        # http://linuxcommand.org/lc3_adv_tput.php
        local BF=${1:-}
        local CAP
        case ${BF} in
            [Bb]) CAP=setab ;;
            [Ff]) CAP=setaf ;;
            [Nn][Cc]) CAP=sgr0 ;;
            *) return ;;
        esac
        local COLOR_IN=${2:-}
        local VAL
        if [[ ${CAP} != "sgr0" ]]; then
            case ${COLOR_IN} in
                [Bb4]) VAL=4 ;; # Blue
                [Cc6]) VAL=6 ;; # Cyan
                [Gg2]) VAL=2 ;; # Green
                [Kk0]) VAL=0 ;; # Black
                [Mm5]) VAL=5 ;; # Magenta
                [Rr1]) VAL=1 ;; # Red
                [Ww7]) VAL=7 ;; # White
                [Yy3]) VAL=3 ;; # Yellow
                *) return ;;
            esac
        fi
        local COLOR_OUT
        if [[ $(tput colors 2> /dev/null) -ge 8 ]]; then
            COLOR_OUT=$(eval tput ${CAP:-} ${VAL:-} 2> /dev/null)
        fi
        echo "${COLOR_OUT:-}"
    else
        return
    fi
}
declare -Agr B=(
    [B]=$(tcolor B B)
    [C]=$(tcolor B C)
    [G]=$(tcolor B G)
    [K]=$(tcolor B K)
    [M]=$(tcolor B M)
    [R]=$(tcolor B R)
    [W]=$(tcolor B W)
    [Y]=$(tcolor B Y)
)
declare -Agr F=(
    [B]=$(tcolor F B)
    [C]=$(tcolor F C)
    [G]=$(tcolor F G)
    [K]=$(tcolor F K)
    [M]=$(tcolor F M)
    [R]=$(tcolor F R)
    [W]=$(tcolor F W)
    [Y]=$(tcolor F Y)
)
readonly NC=$(tcolor NC)

# Log Functions
readonly LOG_FILE="/tmp/dockstarterappconfig.log"
sudo -E chown "${DETECTED_PUID:-$DETECTED_UNAME}":"${DETECTED_PGID:-$DETECTED_UGROUP}" "${LOG_FILE}" > /dev/null 2>&1 || true
log() {
    local TOTERM=${1:-}
    local MESSAGE=${2:-}
    echo -e "${MESSAGE:-}" | (
        if [[ -n ${TOTERM} ]]; then
            tee -a "${LOG_FILE}" >&2
        else
            cat >> "${LOG_FILE}" 2>&1
        fi
    )
}
trace() { log "${TRACE:-}" "${NC}$(date +"%F %T") ${F[B]}[TRACE ]${NC}   $*${NC}"; }
debug() { log "${DEBUG:-}" "${NC}$(date +"%F %T") ${F[B]}[DEBUG ]${NC}   $*${NC}"; }
info() { log "${VERBOSE:-}" "${NC}$(date +"%F %T") ${F[B]}[INFO  ]${NC}   $*${NC}"; }
notice() { log "true" "${NC}$(date +"%F %T") ${F[G]}[NOTICE]${NC}   $*${NC}"; }
warn() { log "true" "${NC}$(date +"%F %T") ${F[Y]}[WARN  ]${NC}   $*${NC}"; }
error() { log "true" "${NC}$(date +"%F %T") ${F[R]}[ERROR ]${NC}   $*${NC}"; }
fatal() {
    log "true" "${NC}$(date +"%F %T") ${B[R]}${F[W]}[FATAL ]${NC}   $*${NC}"
    exit 1
}

# Repo Exists Function
repo_exists() {
    if [[ -d ${SCRIPTPATH}/.git ]] && [[ -d ${SCRIPTPATH}/.scripts ]]; then
        return
    else
        return 1
    fi
}

# Root Check Function
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as a standard user with sudo."
    fi
}

# Script Runner Function
run_script() {
    local SCRIPTSNAME=${1:-}
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    else
        fatal "${SCRIPTPATH}/.scripts/${SCRIPTSNAME}.sh not found."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME=${1:-}
    shift
    if [[ -f ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh ]]; then
        if grep -q "test_${TESTSNAME}" "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"; then
            notice "Testing ${TESTSNAME}."
            # shellcheck source=/dev/null
            source "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh"
            eval "test_${TESTSNAME}" "$@" || fatal "Failed to run ${TESTSNAME}."
            notice "Completed testing ${TESTSNAME}."
        else
            fatal "Test function in ${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
        fi
    else
        fatal "${SCRIPTPATH}/.scripts/${TESTSNAME}.sh not found."
    fi
}

# Version Functions
# https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash#comment92693604_4024263
vergte() { printf '%s\n%s' "${2}" "${1}" | sort -C -V; }
vergt() { ! vergte "${2}" "${1}"; }
verlte() { printf '%s\n%s' "${1}" "${2}" | sort -C -V; }
verlt() { ! verlte "${2}" "${1}"; }

# Cleanup Function
cleanup() {
    local -ri EXIT_CODE=$?

    if repo_exists; then
        info "Setting executable permission on ${SCRIPTNAME}"
        sudo chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "dsac must be executable."
    fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS:-} == false ]]; then
        warn "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi

    if [[ ${EXIT_CODE} -ne 0 ]]; then
        error "DockSTARTer App Config did not finish running successfully."
    fi
    exit ${EXIT_CODE}
    trap - 0 1 2 3 6 14 15
}
trap 'cleanup' 0 1 2 3 6 14 15

# Main Function
main() {
    #Save current log if not empty and rotate logs
    savelog -n -C -l -t "${LOG_FILE}" > /dev/null
    # Arch Check
    readonly ARCH=$(uname -m)
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Terminal Check
    if [[ -t 1 ]]; then
        root_check
    fi
    # Repo Check
    local PROMPT
    local DSAC_COMMAND
    DSAC_COMMAND=$(command -v dsac || true)
    if [[ -L ${DSAC_COMMAND} ]]; then
        local DSAC_SYMLINK
        DSAC_SYMLINK=$(readlink -f "${DSAC_COMMAND}")
        if [[ ${SCRIPTNAME} != "${DSAC_SYMLINK}" ]]; then
            if repo_exists; then
                if [[ ${PROMPT:-} != "GUI" ]]; then
                    PROMPT="CLI"
                fi
                if run_script 'question_prompt' "${PROMPT:-CLI}" N "DockSTARTer App Config installation found at ${DSAC_SYMLINK} location. Would you like to run ${SCRIPTNAME} instead?"; then
                    run_script 'symlink_dsac'
                    DSAC_COMMAND=$(command -v dsac || true)
                    DSAC_SYMLINK=$(readlink -f "${DSAC_COMMAND}")
                fi
                unset PROMPT
            fi
            warn "Attempting to run DockSTARTer App Config from ${DSAC_SYMLINK} location."
            sudo bash "${DSAC_SYMLINK}" -vu
            sudo bash "${DSAC_SYMLINK}" -vi
            exec sudo -E bash "${DSAC_SYMLINK}" "${ARGS[@]:-}"
        fi
    else
        if ! repo_exists; then
            warn "Attempting to clone DockSTARTer App Config repo to ${DETECTED_DSACDIR} location."
            # Anti Sudo Check
            if [[ ${EUID} -eq 0 ]]; then
                fatal "Using sudo during cloning on first run is not supported."
            fi
            git clone https://github.com/GhostWriters/DSAC "${DETECTED_DSACDIR}" || fatal "Failed to clone DockSTARTer App Config repo to ${DETECTED_DSACDIR} location."
            notice "Performing first run install."
            exec sudo -E bash "${DETECTED_DSACDIR}/main.sh" "-vi"
        fi
    fi
    # Sudo Check
    if [[ ${EUID} -ne 0 ]]; then
        exec sudo -E bash "${SCRIPTNAME}" "${ARGS[@]:-}"
    fi
    # Create Symlink
    run_script 'symlink_dsac'
    # Execute CLI Argument Functions
    if [[ -n ${INSTALL:-} ]]; then
        run_script 'run_install'
        exit
    fi
    if [[ -n ${TEST:-} ]]; then
        run_test "${TEST}"
        exit
    fi
    if [[ -n ${UPDATE:-} ]]; then
        if [[ ${UPDATE} == true ]]; then
            run_script 'update_self'
        else
            run_script 'update_self' "${UPDATE}"
        fi
        exit
    fi
    # Run Menus
    PROMPT="GUI"
    run_script 'menu_main'
    notice "DockStarter App Config has finished."
}
main

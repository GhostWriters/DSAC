#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Usage Information
#/ Usage: bash develop.sh [OPTION]
#/
#/ This is the DockSTARTer App Config script used for development.
#/ Any options that apply to dsac will be passed through. See dsac usage for its options
#/ For regular usage you can run without providing any options.
#/
#/  -f --firstrun
#/      Removes DSAC files and runs first run commands
#/  -l --local <folder>
#/      Copies local development files from ~/<folder> folder to ~/.dsac
#/      If <folder> is not provided, it defaults to ~/DSAC
#/  -r --reset
#/      Removes DSAC & DS files files
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

# Script Information
# https://stackoverflow.com/a/246128/1384186
get_scriptname() {
    local SOURCE
    local DIR
    SOURCE="${BASH_SOURCE[0]:-$0}" # https://stackoverflow.com/questions/35006457/choosing-between-0-and-bash-source
    while [[ -L ${SOURCE} ]]; do   # resolve ${SOURCE} until the file is no longer a symlink
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
readonly LOG_TEMP=$(mktemp) || echo "Failed to create temporary log file."
echo "DockSTARTer App Config Log - Develop" > "${LOG_TEMP}"
log() {
    local TOTERM=${1:-}
    local MESSAGE=${2:-}
    echo -e "${MESSAGE:-}" | (
        if [[ -n ${TOTERM} ]]; then
            tee -a "${LOG_TEMP}" >&2
        else
            cat >> "${LOG_TEMP}" 2>&1
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

# Script Runner Function
run_script() {
    local SCRIPTSNAME="${1:-}"
    shift
    if [[ -f ${DETECTED_DSACDIR}/.develop/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${DETECTED_DSACDIR}/.develop/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    elif [[ -f ${DETECTED_DSACDIR}/.scripts/${SCRIPTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${DETECTED_DSACDIR}/.scripts/${SCRIPTSNAME}.sh"
        ${SCRIPTSNAME} "$@"
    else
        fatal "${SCRIPTSNAME}.sh not found in ${DETECTED_DSACDIR}/.develop/ or ${DETECTED_DSACDIR}/.scripts/"
    fi
}

# Root Check
root_check() {
    if [[ ${DETECTED_PUID} == "0" ]] || [[ ${DETECTED_HOMEDIR} == "/root" ]]; then
        fatal "Running as root is not supported. Please run as a standard user without sudo."
    fi
}

# Test Runner Function
run_test() {
    local TESTSNAME="${1:-}"
    shift
    if [[ -f ${DETECTED_DSACDIR}/.tests/${TESTSNAME}.sh ]]; then
        # shellcheck source=/dev/null
        source "${DETECTED_DSACDIR}/.tests/${TESTSNAME}.sh"
        ${TESTSNAME} "$@"
    else
        fatal "${DETECTED_DSACDIR}/.tests/${TESTSNAME}.sh not found."
    fi
}

# Cleanup Function
cleanup() {
    local -ri EXIT_CODE=$?

    if [[ ${SCRIPTPATH} == "${DETECTED_DSACDIR}" ]]; then
        chmod +x "${SCRIPTNAME}" > /dev/null 2>&1 || fatal "dsac must be executable."
    fi
    if [[ ${CI:-} == true ]] && [[ ${TRAVIS:-} == true ]] && [[ ${TRAVIS_SECURE_ENV_VARS} == false ]]; then
        warning "TRAVIS_SECURE_ENV_VARS is false for Pull Requests from remote branches. Please retry failed builds!"
    fi

    sudo sh -c "cat ${LOG_TEMP} >> ${SCRIPTPATH}/dockstarterappconfig.log" || true

    exit ${EXIT_CODE}
    trap - 0 1 2 3 6 14 15
}
trap 'cleanup' 0 1 2 3 6 14 15

cmdline() {
    # http://www.kfirlavi.com/blog/2012/11/14/defensive-bash-programming/
    # http://kirk.webfinish.com/2009/10/bash-shell-script-to-use-getopts-with-gnu-style-long-positional-parameters/
    local ARG=
    local LOCAL_ARGS
    for ARG; do
        local DELIM=""
        case "${ARG}" in
            #translate --gnu-long-options to -g (short options)--backup) LOCAL_ARGS="${LOCAL_ARGS:-}-b " ;;
            --firstrun) LOCAL_ARGS="${LOCAL_ARGS:-}-f " ;;
            --help) LOCAL_ARGS="${LOCAL_ARGS:-}-h " ;;
            --reset) LOCAL_ARGS="${LOCAL_ARGS:-}-r " ;;
            --test) LOCAL_ARGS="${LOCAL_ARGS:-}-t " ;;
            --update) LOCAL_ARGS="${LOCAL_ARGS:-}-u " ;;
            --verbose) LOCAL_ARGS="${LOCAL_ARGS:-}-v " ;;
            --debug) LOCAL_ARGS="${LOCAL_ARGS:-}-x " ;;
            #pass through anything else
            *)
                [[ ${ARG:0:1} == "-" ]] || DELIM='"'
                LOCAL_ARGS="${LOCAL_ARGS:-}${DELIM}${ARG}${DELIM} "
                ;;
        esac
    done

    #Reset the positional parameters to the short options
    eval set -- "${LOCAL_ARGS:-}"

    while getopts ":bcdefghilprt:u:vx" OPTION; do
        case ${OPTION} in
            f)
                readonly FIRSTRUN=1
                ;;
            h)
                usage
                exit
                ;;
            l)
                readonly LOCAL=1
                readonly LOCAL_DIR="${OPTARG:-DSAC}"
                ;;
            r)
                readonly RESET=1
                ;;
            t)
                case ${OPTARG} in
                    dsac_*)
                        info "Passing through test '${OPTARG}' to DSAC as '${OPTARG//dsac_/}'"
                        DSAC_ARGS="${DSAC_ARGS:-}-u ${OPTARG//dsac_/} "
                        ;;
                    "validate" | "VALIDATE" | "v")
                        readonly TEST="run_validate"
                        ;;
                    *)
                        info "Passing through test '${OPTARG}' for development"
                        readonly TEST="${OPTARG}"
                        ;;
                esac
                ;;
            u)
                case ${OPTARG} in
                    dsac_*)
                        info "Passing through '${OPTARG}' to DSAC as '${OPTARG//dsac_/}'"
                        DSAC_ARGS="${DSAC_ARGS:-}-u ${OPTARG//dsac_/} "
                        ;;
                    *)
                        readonly UPDATE=1
                        readonly BRANCH=${OPTARG:-origin/master}
                        ;;
                esac
                ;;
            v)
                readonly VERBOSE=1
                DSAC_ARGS="${DSAC_ARGS:-}-v "
                ;;
            x)
                readonly DEBUG='-x'
                DSAC_ARGS="${DSAC_ARGS:-}-x "
                set -x
                ;;
            :)
                case ${OPTARG} in
                    u)
                        readonly UPDATE=1
                        readonly BRANCH="origin/master"
                        ;;
                    *)
                        fatal "${OPTARG} requires an option."
                        ;;
                esac
                ;;
            *)
                info "Passing through '${OPTION}' to DSAC"
                DSAC_ARGS="${DSAC_ARGS:-}-${OPTION} "
                ;;
        esac
    done
    return 0
}

# Main Function
develop() {
    # Sudo Check
    if [[ ${EUID} == "0" ]]; then
        fatal "Do not run ${SCRIPTNAME} using sudo!"
        exit
    fi
    # Arch Check
    readonly ARCH=$(uname -m)
    if [[ ${ARCH} != "aarch64" ]] && [[ ${ARCH} != "armv7l" ]] && [[ ${ARCH} != "x86_64" ]]; then
        fatal "Unsupported architecture."
    fi
    # Terminal Check
    if [[ -n ${PS1:-} ]] || [[ ${-} == *"i"* ]]; then
        root_check
    fi
    if [[ ${CI:-} != true ]] && [[ ${TRAVIS:-} != true ]]; then
        root_check

        #Process args
        cmdline "${ARGS[@]:-}"

        #Reset
        if [[ -n ${RESET:-} ]] || [[ -n ${FIRSTRUN:-} ]]; then
            run_script 'develop_reset'
        fi
        #First run
        if [[ -n ${FIRSTRUN:-} ]] || [[ -z "$(command -v dsac)" ]] || [[ ! -d .dsac ]]; then
            (bash -c "$(curl -fsSL https://ghostwriters.github.io/DSAC/main.sh)")
            exit
        else
            #Update DSAC
            if [[ -n ${UPDATE:-} ]]; then
                info "Updating DSAC from repo"
                (sudo dsac -u "${BRANCH:-origin/master}")
            fi
            #Update DSAC from development repo and then from local files
            if [[ -n ${LOCAL:-} ]]; then
                run_script 'develop_local' "${LOCAL_DIR}"
            fi
            #Run tests
            if [[ -n ${TEST:-} ]]; then
                run_test "${TEST}"
                exit
            fi
            #Check if this script has been updated
            if [[ -f "${DETECTED_DSACDIR}/.scripts/${SCRIPTNAME}" ]]; then
                if cmp -s "${DETECTED_HOMEDIR}/${SCRIPTNAME}" "${DETECTED_DSACDIR}/.scripts/${SCRIPTNAME}"; then
                    info "${SCRIPTNAME} hasn't changed"
                else
                    cp "${DETECTED_DSACDIR}/.scripts/${SCRIPTNAME}" "${DETECTED_HOMEDIR}/${SCRIPTNAME}"
                    warning "${SCRIPTNAME} has changed. Re-running."
                    bash "${SCRIPTNAME}" "${ARGS[@]:-}"
                    exit
                fi
            fi
        fi
        # Place code for testing below here
        info "Running DSAC..."
        info "DSAC_ARGS='${DSAC_ARGS:-}'"
        (sudo dsac "${DSAC_ARGS:-}")
    fi
}
develop

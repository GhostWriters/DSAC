#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

detect_local_ip() {
    local DETECTED_NIC
    local DETECTED_LOCAL_IP
    DETECTED_NIC=$(ip -o -4 route show to default | head -1 | awk '{print $5}')
    DETECTED_LOCAL_IP=$(ip addr show "${DETECTED_NIC}" | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/')
    echo "${DETECTED_LOCAL_IP}"
}

test_detect_local_ip() {
    run_script 'detect_local_ip'
}

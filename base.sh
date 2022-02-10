#!/bin/bash
# shellcheck disable=SC2034
# SC2034 - Ignore unused variables because this script is meant to be sourced
#          into other scripts.

# This script is included in all stages - prepare, exec and cleanup.
# It defines basic variables and functions.

set -euo pipefail

# create directory for jobs
JOBS="/home/$(whoami)/jobs"
mkdir -p "${JOBS}"

# create directory the specified runner
RUNNER_DIR="${JOBS}/${CUSTOM_ENV_RUNNER}"
mkdir -p "${RUNNER_DIR}"

# define a directory for this specific job
JOB="${RUNNER_DIR}/${CUSTOM_ENV_CI_JOB_ID}"

# ServerAliveInterval helps with bad connectivity from/to the internal
# VPC
SSH="ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=600 -o StrictHostKeyChecking=no"

# Helpers extracting values from the runner's config.json.
function sshUser() {
  cat "${JOB}/${CUSTOM_ENV_RUNNER}/config.json" | jq -r '.user'
}

function runnerArch() {
  cat "${JOB}/${CUSTOM_ENV_RUNNER}/config.json" | jq -r '.runnerArch'
}

function isInternalAWS() {
    if [[ "$CUSTOM_ENV_RUNNER" == *"aws"* && "$CUSTOM_ENV_INTERNAL_NETWORK" == "true" ]];then
        return 0
    else
        return 1
    fi
}

function terraform-wrapper() {
    while true; do
        COUNT=$(pgrep -cf '^terraform'; true)
        if (( COUNT < 5 )); then
            break
        fi
        echo "Too many terraform processes ($COUNT) at the moment, waiting..." >&2
        sleep 10
    done
    if isInternalAWS;then
        while true; do
            INTERNAL_SUBNET_A_FREE=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=InternalA | jq -r .Subnets[].AvailableIpAddressCount)
            INTERNAL_SUBNET_B_FREE=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=InternalB | jq -r .Subnets[].AvailableIpAddressCount)
            if [[ "$INTERNAL_SUBNET_A_FREE" -gt 0 ]];then
                INTERNAL_SUBNET_A_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=InternalA | jq -r .Subnets[].SubnetId)
                terraform "-chdir=$JOB/${CUSTOM_ENV_RUNNER}" "$@" -var="internal_subnet=$INTERNAL_SUBNET_A_ID"
                break
            elif [[ "$INTERNAL_SUBNET_B_FREE" -gt 0 ]];then
                INTERNAL_SUBNET_B_ID=$(aws ec2 describe-subnets --filters Name=tag:Name,Values=InternalB | jq -r .Subnets[].SubnetId)
                terraform "-chdir=$JOB/${CUSTOM_ENV_RUNNER}" "$@" -var="internal_subnet=$INTERNAL_SUBNET_B_ID"
                break
            else
                echo "No free IPs in either internal subnet. Retrying in a bit."
                sleep 30
            fi
        done
    else
         terraform "-chdir=$JOB/${CUSTOM_ENV_RUNNER}" "$@"
    fi
}

# Rename OpenStack authentication variables to the right names.
set +x
export OS_PROJECT_ID="${CUSTOM_ENV_OS_PROJECT_ID:-}"
export OS_AUTH_URL="${CUSTOM_ENV_OS_AUTH_URL:-}"
export OS_USERNAME="${CUSTOM_ENV_OS_USERNAME:-}"
export OS_PASSWORD="${CUSTOM_ENV_OS_PASSWORD:-}"

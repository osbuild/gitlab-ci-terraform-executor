#!/bin/bash
# vim: set ts=2 sw=2 et:
# shellcheck disable=SC2034
# SC2034 - Ignore unused variables because this script is meant to be sourced
#          into other scripts.

# This script is included in all stages - prepare, exec and cleanup.
# It defines basic variables and functions.

set -euo pipefail

# create directory for jobs
JOBS="/home/$(whoami)/jobs"
mkdir -p "${JOBS}"

# define a directory for this specific job
JOB="${JOBS}/${CUSTOM_ENV_CI_JOB_ID}"

# Workaround for https://github.com/hashicorp/terraform/issues/32901
export TF_PLUGIN_CACHE_MAY_BREAK_DEPENDENCY_LOCK_FILE=yes

# ServerAliveInterval helps with bad connectivity from/to the internal
# VPC
SSH="ssh -o ServerAliveInterval=1 -o ServerAliveCountMax=600 -o StrictHostKeyChecking=no"

# Helper for GitLab foldable sections
function section_start() {
  local section_name=$1
  local section_title=$2
  local collapsed=${3:-true}
  if [ "$collapsed" == "true" ]; then
    echo -e "\e[0Ksection_start:$(date +%s):${section_name}[collapsed=true]\r\e[0K\e[1;36m${section_title}\e[0m"
  else
    echo -e "\e[0Ksection_start:$(date +%s):${section_name}\r\e[0K\e[1;36m${section_title}\e[0m"
  fi
}

# Helper for GitLab foldable sections
function section_end() {
  local section_name=$1
  echo -e "\e[0Ksection_end:$(date +%s):${section_name}\r\e[0K"
}

# Helpers extracting values from the runner's config.json.
function sshUser() {
  cat "${JOB}/${CUSTOM_ENV_RUNNER}/config.json" | jq -r '.user'
}

function runnerArch() {
  cat "${JOB}/${CUSTOM_ENV_RUNNER}/config.json" | jq -r '.runnerArch'
}

function waitForUserLogout() {
    COMMAND="who -u | grep -v '?' | wc -l"
    VM_IP=$(cat "${JOB}/ip")
    RESULT=$($SSH "$(sshUser)@${VM_IP}" "$COMMAND")
    while (( "${RESULT:-0}" > 0 )); do
        sleep 30
        RESULT=$($SSH "$(sshUser)@${VM_IP}" "$COMMAND")
    done
}

function terraform-wrapper() {
  # terraform is very memory hungry so we have to limit the maximum number of terraform concurrent processes,
  # otherwise the OOM killer will be mean to a random process
  while true; do
    COUNT=$(pgrep -cf '^terraform'; true)
    if (( "${COUNT:-0}" < 40 )); then
      break
    fi
    echo "Too many terraform processes ($COUNT) at the moment, waiting..." >&2
    sleep 10
  done


  export TF_PLUGIN_CACHE_DIR="$HOME/cache"
  mkdir -p "${TF_PLUGIN_CACHE_DIR}"
  terraform "-chdir=$JOB/${CUSTOM_ENV_RUNNER}" "$@"
}

# Rename OpenStack authentication variables to the right names.
set +x
export OS_PROJECT_ID="${CUSTOM_ENV_OS_PROJECT_ID:-}"
export OS_AUTH_URL="${CUSTOM_ENV_OS_AUTH_URL:-}"
export OS_USERNAME="${CUSTOM_ENV_OS_USERNAME:-}"
export OS_PASSWORD="${CUSTOM_ENV_OS_PASSWORD:-}"

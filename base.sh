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

# alias for launching terraform in the job's directory
TERRAFORM="terraform -chdir=$JOB"

# ServerAliveInterval helps with bad connectivity from/to the internal
# VPC
SSH="ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no"

# Helpers extracting values from the runner's config.json.
function sshUser() {
  cat "${JOB}/config.json" | jq -r '.user'
}

function runnerArch() {
  cat "${JOB}/config.json" | jq -r '.runnerArch'
}

# Rename OpenStack authentication variables to the right names.
set +x
export OS_PROJECT_ID="${CUSTOM_ENV_OS_PROJECT_ID}"
export OS_AUTH_URL="${CUSTOM_ENV_OS_AUTH_URL}"
export OS_USERNAME="${CUSTOM_ENV_OS_USERNAME}"
export OS_PASSWORD="${CUSTOM_ENV_OS_PASSWORD}"

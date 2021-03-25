#!/bin/bash

set -x

BASE="/home/$(whoami)"
TERRAFORM_JOBS="${BASE}/terraform-jobs"
mkdir -p "${TERRAFORM_JOBS}"

TERRAFORM_JOB="${TERRAFORM_JOBS}/${CUSTOM_ENV_CI_JOB_ID}"
mkdir -p "${TERRAFORM_JOB}"

TERRAFORM="terraform -chdir=$TERRAFORM_JOB"

SSH="ssh -o ServerAliveInterval=60 -o StrictHostKeyChecking=no"

function sshUser() {
  cat "${TERRAFORM_JOB}/config.json" | jq -r '.user'
}

function runnerArch() {
  cat "${TERRAFORM_JOB}/config.json" | jq -r '.runnerArch'
}

set +x
export OS_PROJECT_ID="${CUSTOM_ENV_OS_PROJECT_ID}"
export OS_AUTH_URL="${CUSTOM_ENV_OS_AUTH_URL}"
export OS_USERNAME="${CUSTOM_ENV_OS_USERNAME}"
export OS_PASSWORD="${CUSTOM_ENV_OS_PASSWORD}"

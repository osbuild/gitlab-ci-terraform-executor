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

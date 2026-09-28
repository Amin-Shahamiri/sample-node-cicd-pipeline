#!/usr/bin/env bash
set -euo pipefail

TARGET_ENV="$1"
IMAGE_TAG="$2"

echo "Deploying artifact image: ${IMAGE_TAG} to environment: ${TARGET_ENV}"
# Place target cloud/K8s deployment commands here
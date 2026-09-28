#!/usr/bin/env bash
set -euo pipefail

TARGET_ENV="$1"
IMAGE_TAG="$2"

echo "Triggering deployment to ${TARGET_ENV} on VPS..."

ssh -o StrictHostKeyChecking=no "${VPS_USER}@${VPS_HOST}" \
  "sudo /usr/local/bin/deploy-app.sh '${TARGET_ENV}' '${IMAGE_TAG}' '${GITHUB_TOKEN}' '${GITHUB_ACTOR}'"
#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="$1"

echo "Executing HTTP smoke test against ${TARGET_URL}..."
for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${TARGET_URL}/health" || true)
  if [ "$STATUS" = "200" ]; then
    echo "Health check passed!"
    exit 0
  fi
  echo "Waiting for container startup... (Attempt $i/10)"
  sleep 3
done

echo "Smoke test failed with status code: $STATUS"
exit 1
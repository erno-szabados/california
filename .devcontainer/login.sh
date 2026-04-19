#!/usr/bin/env bash
set -euo pipefail
# Avoid printing secrets to logs
set +x

# Prefer Podman secrets path
CREDS_PATH="/run/secrets/azure-creds"
if [ -f "$CREDS_PATH" ]; then
  . "$CREDS_PATH"
else
  echo "No credentials file found at /run/secrets/azure-creds" >&2
  exit 1
fi

# Perform login (uses env vars from sourced file)
az login --service-principal -u "$AZ_ID" -p "$AZ_SECRET" --tenant "$AZ_TENANT"

# Remove sensitive envs from this shell
unset AZ_ID AZ_SECRET AZ_TENANT

exit 0

#!/usr/bin/env bash
set -euo pipefail
# Avoid printing secrets to logs
set +x

# Paths for Podman secrets
AZ_CREDS_PATH="/run/secrets/azure-creds-ml-training"
GH_TOKEN_PATH="/run/secrets/gh-token-california"

# Azure login (env-file format: AZ_ID, AZ_SECRET, AZ_TENANT)
if [ -f "$AZ_CREDS_PATH" ]; then
  . "$AZ_CREDS_PATH"
  az login --service-principal -u "$AZ_ID" -p "$AZ_SECRET" --tenant "$AZ_TENANT"
  unset AZ_ID AZ_SECRET AZ_TENANT
fi

# GitHub login (token-only file)
if [ -f "$GH_TOKEN_PATH" ]; then
  # Use gh's --with-token to read token from stdin (avoids CLI arg exposure)
  gh auth login --with-token < "$GH_TOKEN_PATH"
  # Ensure gh config has restrictive permissions
  if [ -f "$HOME/.config/gh/hosts.yml" ]; then
    chmod 600 "$HOME/.config/gh/hosts.yml" || true
  fi
fi

exit 0

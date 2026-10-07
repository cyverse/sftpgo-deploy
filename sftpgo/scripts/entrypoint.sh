#!/bin/bash
#
# Entrypoint for SFTPGo container.
#
# The external auth hook registers virtual folders through the REST API, which
# needs an API key. A key only exists once SFTPGo is running, and the hook's
# environment is whatever command.env in sftpgo.json lists, so the key is
# injected there at startup instead of being baked into the image.
#
# Bootstrap sequence, skipped when SFTPGO_API_KEY is already set:
#   1. Start SFTPGo in background (sftpgo.json generated at build time)
#   2. Wait for REST API to become ready
#   3. Enable API key auth on the default admin
#   4. Issue an API key
#   5. Stop background SFTPGo
# Then:
#   6. Patch sftpgo.json command.env with the API key and the REST API URL (jq)
#   7. exec sftpgo serve (foreground)
#
# Required environment variables (in addition to those for prep-config-json.sh):
#   SFTPGO_DEFAULT_ADMIN_USERNAME   The default admin username
#   SFTPGO_DEFAULT_ADMIN_PASSWORD   The default admin password
#   SFTPGO_ADMIN_UI_PORT            The TCP port for the web admin / REST API
#
# Optional:
#   SFTPGO_API_KEY                  An API key to use instead of issuing one

set -e

ADMIN_API="http://localhost:${SFTPGO_ADMIN_UI_PORT}"

wait_for_api() {
  local retries=30
  until curl -sf "${ADMIN_API}/healthz" > /dev/null 2>&1; do
    retries=$((retries - 1))
    if [ "$retries" -le 0 ]; then
      echo "ERROR: SFTPGo REST API did not become ready in time" >&2
      exit 1
    fi
    sleep 1
  done
}

get_token() {
  curl -sf -X GET "${ADMIN_API}/api/v2/token" \
    -u "${SFTPGO_DEFAULT_ADMIN_USERNAME}:${SFTPGO_DEFAULT_ADMIN_PASSWORD}" \
    | sed 's/.*"access_token":"\([^"]*\)".*/\1/'
}

enable_api_key_auth() {
  local token="$1"
  curl -sf -X PUT "${ADMIN_API}/api/v2/admins/${SFTPGO_DEFAULT_ADMIN_USERNAME}" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "{\"status\":1,\"username\":\"${SFTPGO_DEFAULT_ADMIN_USERNAME}\",\"password\":\"${SFTPGO_DEFAULT_ADMIN_PASSWORD}\",\"permissions\":[\"*\"],\"filters\":{\"allow_api_key_auth\":true}}" \
    > /dev/null
}

issue_api_key() {
  local token="$1"
  curl -sf -X POST "${ADMIN_API}/api/v2/apikeys" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"sftpgo-auth-irods\",\"scope\":1,\"admin\":\"${SFTPGO_DEFAULT_ADMIN_USERNAME}\"}" \
    | sed 's/.*"key":"\([^"]*\)".*/\1/'
}

log() { echo "[entrypoint] $*"; }

if [ -n "${SFTPGO_API_KEY:-}" ]; then
  # A key was supplied, so there is nothing to issue.
  log "Using the API key from the environment."
  API_KEY="${SFTPGO_API_KEY}"
else
  # Step 1: start SFTPGo in background (sftpgo.json generated at build time)
  log "Starting SFTPGo in background for bootstrap..."
  sftpgo serve &
  SFTPGO_PID=$!

  # Step 2: wait for REST API
  log "Waiting for REST API to become ready..."
  wait_for_api
  log "REST API is ready."

  # Step 3 & 4: get token, enable API key auth, issue key
  log "Enabling API key auth for admin..."
  TOKEN=$(get_token)
  enable_api_key_auth "$TOKEN"

  log "Issuing API key..."
  API_KEY=$(issue_api_key "$TOKEN")

  if [ -z "$API_KEY" ]; then
    log "ERROR: failed to obtain API key from SFTPGo"
    kill "$SFTPGO_PID"
    exit 1
  fi
  log "API key issued successfully."

  # Step 5: stop the bootstrap instance
  log "Stopping bootstrap SFTPGo..."
  kill "$SFTPGO_PID"
  wait "$SFTPGO_PID" 2>/dev/null || true
fi

# Step 6: patch sftpgo.json command.env with the API key and the REST API URL.
# The hook's environment is whatever command.env lists, and the key is only
# known at runtime, so it is injected here rather than baked into the image.
# The URL follows from the port the REST API is already bound to.
log "Patching sftpgo.json with the API key..."
CFG=/etc/sftpgo/sftpgo.json
TMP=$(mktemp)
# Replace rather than append, so that restarting over an already patched
# configuration does not leave two entries for the same variable.
jq --arg base_url "${ADMIN_API}" --arg api_key "${API_KEY}" '
  .command.commands[0].env =
    ((.command.commands[0].env
      | map(select(
          (startswith("SFTPGO_API_BASE_URL=") or startswith("SFTPGO_API_KEY=")) | not
        )))
     + ["SFTPGO_API_BASE_URL=" + $base_url, "SFTPGO_API_KEY=" + $api_key])
' "$CFG" > "$TMP" && mv "$TMP" "$CFG"
log "sftpgo.json patched."

# Step 7: exec foreground SFTPGo
log "Starting SFTPGo (foreground)..."
exec sftpgo serve

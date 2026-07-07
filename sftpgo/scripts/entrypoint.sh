#!/bin/bash
#
# Entrypoint for SFTPGo container.
#
# Bootstrap sequence:
#   1. Start SFTPGo in background (sftpgo.json generated at build time)
#   2. Wait for REST API to become ready
#   3. Enable API key auth on the default admin
#   4. Issue an API key
#   5. Patch sftpgo.json command.env with API key (jq)
#   6. Stop background SFTPGo
#   7. exec sftpgo serve (foreground)
#
# Required environment variables (in addition to those for prep-config-json.sh):
#   SFTPGO_DEFAULT_ADMIN_USERNAME   The default admin username
#   SFTPGO_DEFAULT_ADMIN_PASSWORD   The default admin password
#   SFTPGO_ADMIN_UI_PORT            The TCP port for the web admin / REST API

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

# Step 5: patch sftpgo.json command.env with API key
log "Patching sftpgo.json with API key..."
CFG=/etc/sftpgo/sftpgo.json
TMP=$(mktemp)
jq --arg base_url "${ADMIN_API}" --arg api_key "${API_KEY}" '
  .command.commands[0].env +=
    ["SFTPGO_API_BASE_URL=" + $base_url, "SFTPGO_API_KEY=" + $api_key]
' "$CFG" > "$TMP" && mv "$TMP" "$CFG"
log "sftpgo.json patched."

# Step 6: stop background SFTPGo
log "Stopping bootstrap SFTPGo..."
kill "$SFTPGO_PID"
wait "$SFTPGO_PID" 2>/dev/null || true

# Step 7: exec foreground SFTPGo
log "Starting SFTPGo (foreground)..."
exec sftpgo serve

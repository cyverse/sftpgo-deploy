#!/bin/bash

export ENV_NAME=cyverse_datastore_sftp

# SFTPGo setting
export WEBDAV_PORT=8080
export SFTP_PORT=2022
export SFTPGO_ADMIN_UI_PORT=8022
export SFTPGO_VAULT="/srv/sftpgo"
export SFTPGO_HOME_PATH="$SFTPGO_VAULT/data"
export SFTPGO_ADMIN_USER="sftpgo-admin"
export SFTPGO_ADMIN_PASSWORD="sftpgo-admin-test"
export SFTPGO_LOG_DIR="/var/log/sftpgo"
# Seconds SFTPGo may reuse a successful authentication before calling the
# external auth hook again. A revoked password or public key keeps working for
# up to this long, so keep it short.
export SFTPGO_AUTH_CACHE_TIME=300
# The REST API key the external auth hook registers virtual folders with. Leave
# it empty to have entrypoint.sh issue one at startup; set it to use a key of
# your own instead. Either way the hook is pointed at the REST API on
# SFTPGO_ADMIN_UI_PORT, so there is no URL to configure.
export SFTPGO_API_KEY=""
# iRODS Setting
export IRODS_PROXY_USER=""
export IRODS_PROXY_PASSWORD=""
export IRODS_HOST="data.cyverse.org"
export IRODS_PORT=1247
export IRODS_ZONE="iplant"
export IRODS_REQUIRE_CS_NEGOTIATION=false
export IRODS_CS_NEGOTIATION_POLICY="CS_NEG_DONT_CARE"
export IRODS_AUTH_SCHEME="native"
export IRODS_SSL_CA_CERT_PATH=""
export IRODS_SSL_ALGORITHM="AES-256-CBC"
export IRODS_SSL_KEY_SIZE=32
export IRODS_SSL_SALT_SIZE=8
export IRODS_SSL_HASH_ROUNDS=16
# 'none', 'cert', or 'hostname'. Only 'hostname' verifies the iRODS server
# certificate; go-irodsclient treats 'cert' the same as 'none'. Use 'hostname'
# where the connection is encrypted and the server certificate is verifiable.
export IRODS_SSL_VERIFY_SERVER="none"
export IRODS_SHARED="/iplant/home/shared"
# irodsfs-pool endpoint (e.g., "tcp://host:port", "unix:///path/to/socket"). Leave empty to connect to iRODS directly
export IRODS_POOL_ENDPOINT=""

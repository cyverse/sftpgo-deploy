#!/bin/bash

export ENV_NAME=cyverse_datastore_sftp

# SFTPGo setting
export WEBDAV_PORT=8080
export SFTP_PORT=2022
export SFTPGO_ADMIN_UI_PORT=8080
export SFTPGO_VAULT="/srv/sftpgo"
export SFTPGO_HOME_PATH="$SFTPGO_VAULT/data"
export SFTPGO_ADMIN_USER="sftpgo-admin"
export SFTPGO_ADMIN_PASSWORD="sftpgo-admin-test"
export SFTPGO_LOG_DIR="/var/log/sftpgo"
# iRODS Setting
export IRODS_PROXY_USER=""
export IRODS_PROXY_PASSWORD=""
export IRODS_HOST="data.cyverse.org"
export IRODS_PORT=1247
export IRODS_ZONE="iplant"
export IRODS_AUTH_SCHEME="native"
export IRODS_SSL_CA_CERT_PATH=""
export IRODS_SSL_ALGORITHM="AES-256-CBC"
export IRODS_SSL_KEY_SIZE=32
export IRODS_SSL_SALT_SIZE=8
export IRODS_SSL_HASH_ROUNDS=16
export IRODS_SHARED="/iplant/home/shared"
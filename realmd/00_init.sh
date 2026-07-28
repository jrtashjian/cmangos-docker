#!/bin/bash

source /usr/share/cmangos/init-lib.sh

init_base_db_env
init_db_env LOGIN_DB login

copy_configs /opt/cmangos/configs/ /opt/cmangos/etc/

create_db_config "LOGIN_DB" "/opt/database/login_db.config" "Creating login_db.config"
ensure_custom_install_full_db

ensure_database LOGIN_DB login \
	/opt/cmangos/sql/base/realmd.sql \
	/opt/database/login_db.config \
	LOGIN

if ! ensure_accounts LOGIN_DB; then
	echo "[ERR] Account setup failed"
	exit 1
fi

REALMD_LOGINDATABASEINFO="${LOGIN_DB_HOST};${LOGIN_DB_PORT};${LOGIN_DB_USER};${LOGIN_DB_PASS};${LOGIN_DB_NAME}"
REALMD_LOGSDIR="/opt/cmangos/etc/logs"

update_config REALMD_ /opt/cmangos/etc/realmd.conf

mkdir -p $REALMD_LOGSDIR

rm -f /opt/cmangos/etc/.login_db_initialized
rm -f /opt/cmangos/etc/.initialized

cd /opt/cmangos/bin/
exec ./realmd

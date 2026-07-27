#!/bin/bash

source /usr/share/cmangos/init-lib.sh

init_base_db_env
init_db_env LOGIN_DB login
init_db_env WORLD_DB world
init_db_env CHARACTERS_DB characters
init_db_env LOGS_DB logs

REALM_ID="${REALM_ID:=1}"
REALM_NAME="${REALM_NAME:=MaNGOS}"
REALM_ADDRESS="${REALM_ADDRESS:=127.0.0.1}"
REALM_PORT="${REALM_PORT:=8085}"
REALM_GAMETYPE="${REALM_GAMETYPE:=NORMAL}"

case "${REALM_GAMETYPE^^}" in
	"NORMAL") MANGOSD_GAMETYPE=0 ;;
	"PVP")    MANGOSD_GAMETYPE=1 ;;
	"RP")     MANGOSD_GAMETYPE=6 ;;
	"RPPVP")  MANGOSD_GAMETYPE=8 ;;
	*)        MANGOSD_GAMETYPE=0 ;;
esac

copy_configs /opt/cmangos/configs/ /opt/cmangos/etc/

create_db_config "WORLD_DB" "/opt/database/world_db.config" "Creating world_db.config"
create_db_config "CHARACTERS_DB" "/opt/database/characters_db.config" "Creating characters_db.config"
create_db_config "LOGS_DB" "/opt/database/logs_db.config" "Creating logs_db.config"
ensure_custom_install_full_db

wait_for_db LOGIN_DB
sql_exec "LOGIN_DB" \
	"INSERT INTO realmlist (id,name,address,port,icon) VALUES (${REALM_ID},'${REALM_NAME}','${REALM_ADDRESS}','${REALM_PORT}','${MANGOSD_GAMETYPE}') ON DUPLICATE KEY UPDATE name='${REALM_NAME}', address='${REALM_ADDRESS}', port='${REALM_PORT}', icon='${MANGOSD_GAMETYPE}';" \
	"Updating realmlist with '${REALM_NAME}'"

WORLD_INSTALL_ROLE="WORLD"
if [ "$INSTALL_FULL_DB" = TRUE ]; then
	WORLD_INSTALL_ROLE="CONTENT"
fi

ensure_database WORLD_DB world \
	/opt/cmangos/sql/base/mangos.sql \
	/opt/database/world_db.config \
	"$WORLD_INSTALL_ROLE" \
	"$WORLD_DB_EXTRA_GRANTS"

ensure_database CHARACTERS_DB characters \
	/opt/cmangos/sql/base/characters.sql \
	/opt/database/characters_db.config \
	CHARACTERS

ensure_database LOGS_DB logs \
	/opt/cmangos/sql/base/logs.sql \
	/opt/database/logs_db.config \
	LOGS

MANGOSD_LOGINDATABASEINFO="${LOGIN_DB_HOST};${LOGIN_DB_PORT};${LOGIN_DB_USER};${LOGIN_DB_PASS};${LOGIN_DB_NAME}"
MANGOSD_WORLDDATABASEINFO="${WORLD_DB_HOST};${WORLD_DB_PORT};${WORLD_DB_USER};${WORLD_DB_PASS};${WORLD_DB_NAME}"
MANGOSD_CHARACTERDATABASEINFO="${CHARACTERS_DB_HOST};${CHARACTERS_DB_PORT};${CHARACTERS_DB_USER};${CHARACTERS_DB_PASS};${CHARACTERS_DB_NAME}"
MANGOSD_LOGSDATABASEINFO="${LOGS_DB_HOST};${LOGS_DB_PORT};${LOGS_DB_USER};${LOGS_DB_PASS};${LOGS_DB_NAME}"
MANGOSD_LOGSDIR="/opt/cmangos/etc/logs"
MANGOSD_DATADIR="/opt/cmangos-data"
MANGOSD_REALMID=$REALM_ID

update_config MANGOSD_ /opt/cmangos/etc/mangosd.conf
update_config AHBOT_ /opt/cmangos/etc/ahbot.conf
update_config ANTICHEAT_ /opt/cmangos/etc/anticheat.conf
update_config PLAYERBOT_ /opt/cmangos/etc/playerbot.conf

mkdir -p $MANGOSD_LOGSDIR

rm -f /opt/cmangos/etc/.world_db_initialized
rm -f /opt/cmangos/etc/.characters_db_initialized
rm -f /opt/cmangos/etc/.logs_db_initialized
rm -f /opt/cmangos/etc/.initialized

cd /opt/cmangos/bin/
exec ./mangosd

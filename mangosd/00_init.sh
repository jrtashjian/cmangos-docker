#!/bin/bash

# Environment Vars:
#
# - DB_HOST
# - DB_PORT
# - DB_USER
# - DB_PASS
# - DB_NAME
# - DB_ROOT_PASS
#

LOGIN_DB_HOST="${LOGIN_DB_HOST:=$DB_HOST}"
LOGIN_DB_PORT="${LOGIN_DB_PORT:=$DB_PORT}"
LOGIN_DB_USER="${LOGIN_DB_USER:=$DB_USER}"
LOGIN_DB_PASS="${LOGIN_DB_PASS:=$DB_PASS}"
LOGIN_DB_NAME="${LOGIN_DB_NAME:=login}"
LOGIN_DB_ROOT_PASS="${LOGIN_DB_ROOT_PASS:=$DB_ROOT_PASS}"

WORLD_DB_HOST="${WORLD_DB_HOST:=$DB_HOST}"
WORLD_DB_PORT="${WORLD_DB_PORT:=$DB_PORT}"
WORLD_DB_USER="${WORLD_DB_USER:=$DB_USER}"
WORLD_DB_PASS="${WORLD_DB_PASS:=$DB_PASS}"
WORLD_DB_NAME="${WORLD_DB_NAME:=world}"
WORLD_DB_ROOT_PASS="${WORLD_DB_ROOT_PASS:=$DB_ROOT_PASS}"

CHARACTERS_DB_HOST="${CHARACTERS_DB_HOST:=$DB_HOST}"
CHARACTERS_DB_PORT="${CHARACTERS_DB_PORT:=$DB_PORT}"
CHARACTERS_DB_USER="${CHARACTERS_DB_USER:=$DB_USER}"
CHARACTERS_DB_PASS="${CHARACTERS_DB_PASS:=$DB_PASS}"
CHARACTERS_DB_NAME="${CHARACTERS_DB_NAME:=characters}"
CHARACTERS_DB_ROOT_PASS="${CHARACTERS_DB_ROOT_PASS:=$DB_ROOT_PASS}"

LOGS_DB_HOST="${LOGS_DB_HOST:=$DB_HOST}"
LOGS_DB_PORT="${LOGS_DB_PORT:=$DB_PORT}"
LOGS_DB_USER="${LOGS_DB_USER:=$DB_USER}"
LOGS_DB_PASS="${LOGS_DB_PASS:=$DB_PASS}"
LOGS_DB_NAME="${LOGS_DB_NAME:=logs}"
LOGS_DB_ROOT_PASS="${LOGS_DB_ROOT_PASS:=$DB_ROOT_PASS}"

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900

if [ $? -eq 0 ]; then
    # Check if intialized
    if [ ! -f "/opt/cmangos/etc/.intialized" ]; then
		# Copy configs to volume
		cp /opt/cmangos/configs/* /opt/cmangos/etc/
        mv -v /opt/cmangos/etc/ahbot.conf.dist /opt/cmangos/etc/ahbot.conf
        mv -v /opt/cmangos/etc/anticheat.conf.dist /opt/cmangos/etc/anticheat.conf
        mv -v /opt/cmangos/etc/mangosd.conf.dist /opt/cmangos/etc/mangosd.conf
        mv -v /opt/cmangos/etc/playerbot.conf.dist /opt/cmangos/etc/playerbot.conf

        # Configure DB Settings
        sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${LOGIN_DB_HOST}';'${LOGIN_DB_PORT}';'${LOGIN_DB_USER}';'${LOGIN_DB_PASS}';'${LOGIN_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/WorldDatabaseInfo.*/WorldDatabaseInfo = "'${WORLD_DB_HOST}';'${WORLD_DB_PORT}';'${WORLD_DB_USER}';'${WORLD_DB_PASS}';'${WORLD_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/CharacterDatabaseInfo.*/CharacterDatabaseInfo = "'${CHARACTERS_DB_HOST}';'${CHARACTERS_DB_PORT}';'${CHARACTERS_DB_USER}';'${CHARACTERS_DB_PASS}';'${CHARACTERS_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/LogsDatabaseInfo.*/LogsDatabaseInfo = "'${LOGS_DB_HOST}';'${LOGS_DB_PORT}';'${LOGS_DB_USER}';'${LOGS_DB_PASS}';'${LOGS_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf

        # Additional configuration
        sed -i 's/LogsDir.*/LogsDir = "\/opt\/cmangos\/etc\/logs"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/DataDir.*/DataDir = "\/opt\/cmangos-data"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/Ra.Enable \= 0/Ra.Enable \= 1/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/Console\.Enable \= 1/Console\.Enable \= 0/g' /opt/cmangos/etc/mangosd.conf

        # Create DB
        mysql -h $WORLD_DB_HOST -u root -p$WORLD_DB_ROOT_PASS -e "CREATE DATABASE ${WORLD_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $CHARACTERS_DB_HOST -u root -p$CHARACTERS_DB_ROOT_PASS -e "CREATE DATABASE ${CHARACTERS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $LOGS_DB_HOST -u root -p$LOGS_DB_ROOT_PASS -e "CREATE DATABASE ${LOGS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"

        mysql -h $WORLD_DB_HOST -u root -p$WORLD_DB_ROOT_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${WORLD_DB_NAME}.* TO ${WORLD_DB_USER}@'%';"
        mysql -h $CHARACTERS_DB_HOST -u root -p$CHARACTERS_DB_ROOT_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${CHARACTERS_DB_NAME}.* TO ${CHARACTERS_DB_USER}@'%';"
        mysql -h $LOGS_DB_HOST -u root -p$LOGS_DB_ROOT_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGS_DB_NAME}.* TO ${LOGS_DB_USER}@'%';"

        mysql -h $WORLD_DB_HOST -u $WORLD_DB_USER -p$WORLD_DB_PASS $WORLD_DB_NAME < /opt/cmangos/sql/mangos.sql
        mysql -h $CHARACTERS_DB_HOST -u $CHARACTERS_DB_USER -p$CHARACTERS_DB_PASS $CHARACTERS_DB_NAME < /opt/cmangos/sql/characters.sql
        mysql -h $LOGS_DB_HOST -u $LOGS_DB_USER -p$LOGS_DB_PASS $LOGS_DB_NAME < /opt/cmangos/sql/logs.sql

        # Add required data for an empty world
        mysql -h $WORLD_DB_HOST -u $WORLD_DB_USER -p$WORLD_DB_PASS $WORLD_DB_NAME < /opt/cmangos/sql/initial-tables.sql

        # Create .initialized file
        touch /opt/cmangos/etc/.intialized
    fi

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./mangosd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

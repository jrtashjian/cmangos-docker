#!/bin/bash

# Environment Vars:

DB_HOST="${DB_HOST:=database}"
DB_PORT="${DB_PORT:=3306}"
DB_USER="${DB_USER:=mangos}"
DB_PASS="${DB_PASS:=mangos}"
DB_NAME="${DB_NAME:=mangos}"
DB_ADMIN_USER="${DB_ADMIN_USER:=root}"
DB_ADMIN_PASS="${DB_ADMIN_PASS:=mangos}"

LOGIN_DB_HOST="${LOGIN_DB_HOST:=$DB_HOST}"
LOGIN_DB_PORT="${LOGIN_DB_PORT:=$DB_PORT}"
LOGIN_DB_USER="${LOGIN_DB_USER:=$DB_USER}"
LOGIN_DB_PASS="${LOGIN_DB_PASS:=$DB_PASS}"
LOGIN_DB_NAME="${LOGIN_DB_NAME:=login}"
LOGIN_DB_ADMIN_USER="${LOGIN_DB_ADMIN_USER:=$DB_ADMIN_USER}"
LOGIN_DB_ADMIN_PASS="${LOGIN_DB_ADMIN_PASS:=$DB_ADMIN_PASS}"

WORLD_DB_HOST="${WORLD_DB_HOST:=$DB_HOST}"
WORLD_DB_PORT="${WORLD_DB_PORT:=$DB_PORT}"
WORLD_DB_USER="${WORLD_DB_USER:=$DB_USER}"
WORLD_DB_PASS="${WORLD_DB_PASS:=$DB_PASS}"
WORLD_DB_NAME="${WORLD_DB_NAME:=world}"
WORLD_DB_ADMIN_USER="${WORLD_DB_ADMIN_USER:=$DB_ADMIN_USER}"
WORLD_DB_ADMIN_PASS="${WORLD_DB_ADMIN_PASS:=$DB_ADMIN_PASS}"

CHARACTERS_DB_HOST="${CHARACTERS_DB_HOST:=$DB_HOST}"
CHARACTERS_DB_PORT="${CHARACTERS_DB_PORT:=$DB_PORT}"
CHARACTERS_DB_USER="${CHARACTERS_DB_USER:=$DB_USER}"
CHARACTERS_DB_PASS="${CHARACTERS_DB_PASS:=$DB_PASS}"
CHARACTERS_DB_NAME="${CHARACTERS_DB_NAME:=characters}"
CHARACTERS_DB_ADMIN_USER="${CHARACTERS_DB_ADMIN_USER:=$DB_ADMIN_USER}"
CHARACTERS_DB_ADMIN_PASS="${CHARACTERS_DB_ADMIN_PASS:=$DB_ADMIN_PASS}"

LOGS_DB_HOST="${LOGS_DB_HOST:=$DB_HOST}"
LOGS_DB_PORT="${LOGS_DB_PORT:=$DB_PORT}"
LOGS_DB_USER="${LOGS_DB_USER:=$DB_USER}"
LOGS_DB_PASS="${LOGS_DB_PASS:=$DB_PASS}"
LOGS_DB_NAME="${LOGS_DB_NAME:=logs}"
LOGS_DB_ADMIN_USER="${LOGS_DB_ADMIN_USER:=$DB_ADMIN_USER}"
LOGS_DB_ADMIN_PASS="${LOGS_DB_ADMIN_PASS:=$DB_ADMIN_PASS}"

REALM_ID="${REALM_ID:=1}"
REALM_NAME="${REALM_NAME:=MaNGOS}"
REALM_ADDRESS="${REALM_ADDRESS:=127.0.0.1}"
REALM_PORT="${REALM_PORT:=8085}"

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900

if [ $? -eq 0 ]; then
    # Check if initialized
    if [ ! -f "/opt/cmangos/etc/.initialized" ]; then
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
        mysql -h $WORLD_DB_HOST -u $WORLD_DB_ADMIN_USER -p$WORLD_DB_ADMIN_PASS -e "CREATE DATABASE ${WORLD_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $CHARACTERS_DB_HOST -u $CHARACTERS_DB_ADMIN_USER -p$CHARACTERS_DB_ADMIN_PASS -e "CREATE DATABASE ${CHARACTERS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $LOGS_DB_HOST -u $LOGS_DB_ADMIN_USER -p$LOGS_DB_ADMIN_PASS -e "CREATE DATABASE ${LOGS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"

        mysql -h $WORLD_DB_HOST -u $WORLD_DB_ADMIN_USER -p$WORLD_DB_ADMIN_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${WORLD_DB_NAME}.* TO ${WORLD_DB_USER}@'%';"
        mysql -h $CHARACTERS_DB_HOST -u $CHARACTERS_DB_ADMIN_USER -p$CHARACTERS_DB_ADMIN_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${CHARACTERS_DB_NAME}.* TO ${CHARACTERS_DB_USER}@'%';"
        mysql -h $LOGS_DB_HOST -u $LOGS_DB_ADMIN_USER -p$LOGS_DB_ADMIN_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGS_DB_NAME}.* TO ${LOGS_DB_USER}@'%';"

        # INSTALL_FULL_DB
        if [ "$INSTALL_FULL_DB" = TRUE ]; then
            wget "https://github.com/cmangos/${CMANGOS_CORE}-db/releases/download/latest/${CMANGOS_CORE}-all-db.zip"
            unzip ${CMANGOS_CORE}-all-db.zip

            mysql -h $WORLD_DB_HOST -u $WORLD_DB_USER -p$WORLD_DB_PASS $WORLD_DB_NAME < /${CMANGOS_CORE}mangos.sql
            mysql -h $CHARACTERS_DB_HOST -u $CHARACTERS_DB_USER -p$CHARACTERS_DB_PASS $CHARACTERS_DB_NAME < /${CMANGOS_CORE}characters.sql
            mysql -h $LOGS_DB_HOST -u $LOGS_DB_USER -p$LOGS_DB_PASS $LOGS_DB_NAME < /${CMANGOS_CORE}logs.sql

            rm /$CMANGOS_CORE*.zip /$CMANGOS_CORE*.sql
        else
            mysql -h $WORLD_DB_HOST -u $WORLD_DB_USER -p$WORLD_DB_PASS $WORLD_DB_NAME < /opt/cmangos/sql/mangos.sql
            mysql -h $CHARACTERS_DB_HOST -u $CHARACTERS_DB_USER -p$CHARACTERS_DB_PASS $CHARACTERS_DB_NAME < /opt/cmangos/sql/characters.sql
            mysql -h $LOGS_DB_HOST -u $LOGS_DB_USER -p$LOGS_DB_PASS $LOGS_DB_NAME < /opt/cmangos/sql/logs.sql
            # Add required data for an empty world
            mysql -h $WORLD_DB_HOST -u $WORLD_DB_USER -p$WORLD_DB_PASS $WORLD_DB_NAME < /opt/cmangos/sql/initial-tables.sql
        fi

        # Create .initialized file
        touch /opt/cmangos/etc/.initialized
    fi

    # Create or update server in realmlist.
    REALM_FOUND=$(mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -s -N -e "SELECT 1 FROM realmlist WHERE id=${REALM_ID};" 2>&1)
    if [ -z $REALM_FOUND ]; then
        echo "NOT EXISTS"
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -s -N -e "INSERT INTO realmlist (id,name,address,port) VALUES (${REALM_ID},'${REALM_NAME}','${REALM_ADDRESS}',${REALM_PORT});"
    else
        echo "EXISTS"
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -s -N -e "UPDATE realmlist SET name='${REALM_NAME}', address='${REALM_ADDRESS}', port=${REALM_PORT} WHERE id=${REALM_ID};"
    fi

    sed -i 's/RealmID.*/RealmID \= '${REALM_ID}'/g' /opt/cmangos/etc/mangosd.conf

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./mangosd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

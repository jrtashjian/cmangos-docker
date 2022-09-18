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

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900

if [ $? -eq 0 ]; then
    # Check if initialized
    if [ ! -f "/opt/cmangos/etc/.initialized" ]; then
		# Copy configs to volume
		cp /opt/cmangos/configs/* /opt/cmangos/etc/
        mv -v /opt/cmangos/etc/realmd.conf.dist /opt/cmangos/etc/realmd.conf

        # Configure DB Settings
        sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${LOGIN_DB_HOST}';'${LOGIN_DB_PORT}';'${LOGIN_DB_USER}';'${LOGIN_DB_PASS}';'${LOGIN_DB_NAME}'"/g' /opt/cmangos/etc/realmd.conf

        # Create DB
        mysql -h $LOGIN_DB_HOST -u root -p$LOGIN_DB_ROOT_PASS -e "CREATE DATABASE ${LOGIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $LOGIN_DB_HOST -u root -p$LOGIN_DB_ROOT_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGIN_DB_NAME}.* TO ${LOGIN_DB_USER}@'%';"

        # INSTALL_FULL_DB
        if [ "$INSTALL_FULL_DB" = TRUE ]; then
            wget "https://github.com/cmangos/${CMANGOS_CORE}-db/releases/download/latest/${CMANGOS_CORE}-all-db.zip"
            unzip ${CMANGOS_CORE}-all-db.zip

            mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_USER -p$LOGIN_DB_PASS $LOGIN_DB_NAME < /${CMANGOS_CORE}realmd.sql

            rm /$CMANGOS_CORE*.zip /$CMANGOS_CORE*.sql
        else
            mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_USER -p$LOGIN_DB_PASS $LOGIN_DB_NAME < /opt/cmangos/sql/realmd.sql
        fi

        # Create .initialized file
        touch /opt/cmangos/etc/.initialized
    fi

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./realmd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

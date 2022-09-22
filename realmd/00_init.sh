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
        mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_ADMIN_USER -p$LOGIN_DB_ADMIN_PASS -e "CREATE DATABASE ${LOGIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_ADMIN_USER -p$LOGIN_DB_ADMIN_PASS -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGIN_DB_NAME}.* TO ${LOGIN_DB_USER}@'%';"

        # INSTALL_FULL_DB
        if [ "$INSTALL_FULL_DB" = TRUE ]; then
            wget "https://github.com/cmangos/${CMANGOS_CORE}-db/releases/download/latest/${CMANGOS_CORE}-all-db.zip"
            unzip ${CMANGOS_CORE}-all-db.zip

            mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_USER -p$LOGIN_DB_PASS $LOGIN_DB_NAME < /${CMANGOS_CORE}realmd.sql

            rm /$CMANGOS_CORE*.zip /$CMANGOS_CORE*.sql
        else
            mysql -h $LOGIN_DB_HOST -u $LOGIN_DB_USER -p$LOGIN_DB_PASS $LOGIN_DB_NAME < /opt/cmangos/sql/realmd.sql
        fi

        # Remove all default accounts
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -s -N -e "DELETE FROM account;"

        # Create .initialized file
        touch /opt/cmangos/etc/.initialized
    fi

    # Create or update initial accounts
    case $CMANGOS_CORE in
        tbc)
        EXPANSION=1
        ;;
        wotlk)
        EXPANSION=2
        ;;
        *)
        EXPANSION=0
        ;;
    esac

    if [ ! -z "$ACCOUNT_ADMIN_USER" ]; then
        ACCOUNT_ADMIN_DATA=($(php -f /account-create.php $ACCOUNT_ADMIN_USER $ACCOUNT_ADMIN_PASS))
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -N -e "INSERT INTO account (username,gmlevel,v,s,expansion) VALUES ('${ACCOUNT_ADMIN_USER}',3,'${ACCOUNT_ADMIN_DATA[1]}','${ACCOUNT_ADMIN_DATA[0]}',${EXPANSION}) ON DUPLICATE KEY UPDATE gmlevel=3, v='${ACCOUNT_ADMIN_DATA[1]}', s='${ACCOUNT_ADMIN_DATA[0]}', expansion=${EXPANSION};"
    fi
    if [ ! -z "$ACCOUNT_GM_USER" ]; then
        ACCOUNT_GM_DATA=($(php -f /account-create.php $ACCOUNT_GM_USER $ACCOUNT_GM_PASS))
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -N -e "INSERT INTO account (username,gmlevel,v,s,expansion) VALUES ('${ACCOUNT_GM_USER}',2,'${ACCOUNT_GM_DATA[1]}','${ACCOUNT_GM_DATA[0]}',${EXPANSION}) ON DUPLICATE KEY UPDATE gmlevel=2, v='${ACCOUNT_GM_DATA[1]}', s='${ACCOUNT_GM_DATA[0]}', expansion=${EXPANSION};"
    fi
    if [ ! -z "$ACCOUNT_MOD_USER" ]; then
        ACCOUNT_MOD_DATA=($(php -f /account-create.php $ACCOUNT_MOD_USER $ACCOUNT_MOD_PASS))
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -N -e "INSERT INTO account (username,gmlevel,v,s,expansion) VALUES ('${ACCOUNT_MOD_USER}',1,'${ACCOUNT_MOD_DATA[1]}','${ACCOUNT_MOD_DATA[0]}',${EXPANSION}) ON DUPLICATE KEY UPDATE gmlevel=1, v='${ACCOUNT_MOD_DATA[1]}', s='${ACCOUNT_MOD_DATA[0]}', expansion=${EXPANSION};"
    fi
    if [ ! -z "$ACCOUNT_PLAYER_USER" ]; then
        ACCOUNT_PLAYER_DATA=($(php -f /account-create.php $ACCOUNT_PLAYER_USER $ACCOUNT_PLAYER_PASS))
        mysql -h $LOGIN_DB_HOST -P $LOGIN_DB_PORT -u $LOGIN_DB_USER -p$LOGIN_DB_PASS -D "$LOGIN_DB_NAME" -N -e "INSERT INTO account (username,gmlevel,v,s,expansion) VALUES ('${ACCOUNT_PLAYER_USER}',0,'${ACCOUNT_PLAYER_DATA[1]}','${ACCOUNT_PLAYER_DATA[0]}',${EXPANSION}) ON DUPLICATE KEY UPDATE gmlevel=0, v='${ACCOUNT_PLAYER_DATA[1]}', s='${ACCOUNT_PLAYER_DATA[0]}', expansion=${EXPANSION};"
    fi

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./realmd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

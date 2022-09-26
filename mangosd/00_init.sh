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

# Execute SQL command with admin credentials.
# sql_exec_admin "env_var_prefix" "sql" "message"
function sql_exec_admin() {
	sql_exec "$@" "admin"
}

# Execute SQL command.
# sql_exec "env_var_prefix" "sql" "message" "admin"
function sql_exec() {
	if [ ! -z "$3" ]; then echo -n "$3 ... "; fi

	local DBHOST="$1_HOST"
	local DBPORT="$1_PORT"
	local DBNAME="$1_NAME"
	local DBUSER="$1_USER"
	local DBPASS="$1_PASS"

	if [[ "$4" == "admin" ]]; then
		local DBUSER="$1_ADMIN_USER"
		local DBPASS="$1_ADMIN_PASS"
	fi

	export MYSQL_PWD="${!DBPASS}"

    if [[ "$4" == "admin" ]]; then
        MYSQL_ERROR=$(mysql -h "${!DBHOST}" -P "${!DBPORT}" -u "${!DBUSER}" -s -N -e "$2" 2>&1)
    else
        MYSQL_ERROR=$(mysql -h "${!DBHOST}" -P "${!DBPORT}" -u "${!DBUSER}" -s -N -D "${!DBNAME}" -e "$2" 2>&1)
    fi

	if [[ $? != 0 ]]; then
		if [ ! -z "$3" ]; then
			echo "FAILED!"
			echo ">>> $MYSQL_ERROR"
		fi
		return 1
	else
		if [ ! -z "$3" ]; then echo "SUCCESS"; fi
	fi

	return 0
}

# Execute SQL commands from file.
# sql_file_exec "prefix" "sql_file" "message"
function sql_file_exec() {
    if [ ! -z "$3" ]; then echo -n "$3 ... "; fi

	local DBHOST="$1_HOST"
	local DBPORT="$1_PORT"
	local DBNAME="$1_NAME"
	local DBUSER="$1_USER"
	local DBPASS="$1_PASS"

	export MYSQL_PWD="${!DBPASS}"
    MYSQL_ERROR=$(mysql -h "${!DBHOST}" -P "${!DBPORT}" -u "${!DBUSER}" -s -N -D "${!DBNAME}" < "$2" 2>&1)

	if [[ $? != 0 ]]; then
		if [ ! -z "$3" ]; then
			echo "FAILED!"
			echo ">>> $MYSQL_ERROR"
		fi
		return 1
	else
		if [ ! -z "$3" ]; then echo "SUCCESS"; fi
	fi

	return 0
}

# copy_configs "input_path" "output_path"
function copy_configs() {
	find $1 -type f -path '*.dist' -exec bash -c 'FILE=$(basename ${0}); cp '$1'$FILE '$2'${FILE//.dist/}' {} \;
}

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900

if [ $? -eq 0 ]; then
    # Check if initialized
    if [ ! -f "/opt/cmangos/etc/.initialized" ]; then
		# Copy configs to volume
        copy_configs /opt/cmangos/configs/ /opt/cmangos/etc/

        # Create DB
        sql_exec_admin "WORLD_DB" \
            "CREATE DATABASE ${WORLD_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
            "Create database ${WORLD_DB_NAME}"

        sql_exec_admin "CHARACTERS_DB" \
            "CREATE DATABASE ${CHARACTERS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
            "Create database ${CHARACTERS_DB_NAME}"

        sql_exec_admin "LOGS_DB" \
            "CREATE DATABASE ${LOGS_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
            "Create database ${LOGS_DB_NAME}"

        sql_exec_admin "WORLD_DB" \
            "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${WORLD_DB_NAME}.* TO ${WORLD_DB_USER}@'%';" \
            "Grant all permissions to ${WORLD_DB_USER} on the ${WORLD_DB_NAME} database"

        sql_exec_admin "CHARACTERS_DB" \
            "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${CHARACTERS_DB_NAME}.* TO ${CHARACTERS_DB_USER}@'%';" \
            "Grant all permissions to ${CHARACTERS_DB_USER} on the ${CHARACTERS_DB_NAME} database"

        sql_exec_admin "LOGS_DB" \
            "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGS_DB_NAME}.* TO ${LOGS_DB_USER}@'%';" \
            "Grant all permissions to ${LOGS_DB_USER} on the ${LOGS_DB_NAME} database"

        # Import DB
        WORLD_SQL=/opt/cmangos/sql/mangos.sql
        CHARACTERS_SQL=/opt/cmangos/sql/characters.sql
        LOGS_SQL=/opt/cmangos/sql/logs.sql

        if [ "$INSTALL_FULL_DB" = TRUE ]; then
            wget "https://github.com/cmangos/${CMANGOS_CORE}-db/releases/download/latest/${CMANGOS_CORE}-all-db.zip"
            unzip ${CMANGOS_CORE}-all-db.zip

            WORLD_SQL=/${CMANGOS_CORE}mangos.sql
            CHARACTERS_SQL=/${CMANGOS_CORE}characters.sql
            LOGS_SQL=/${CMANGOS_CORE}logs.sql
        fi

        sql_file_exec "WORLD_DB" $WORLD_SQL "Installing world database"
        sql_file_exec "CHARACTERS_DB" $CHARACTERS_SQL "Installing characters database"
        sql_file_exec "LOGS_DB" $LOGS_SQL "Installing logs database"

        # Add required data for an empty world
        if [ ! "$INSTALL_FULL_DB" = TRUE ]; then
            sql_file_exec "WORLD_DB" /opt/cmangos/sql/initial-tables.sql "Adding additional data for an empty world"
        fi

        # Cleanup
        rm -f /$CMANGOS_CORE*.zip /$CMANGOS_CORE*.sql

        # Create .initialized file
        touch /opt/cmangos/etc/.initialized
    fi

    # Update mangosd.conf
    sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${LOGIN_DB_HOST}';'${LOGIN_DB_PORT}';'${LOGIN_DB_USER}';'${LOGIN_DB_PASS}';'${LOGIN_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/WorldDatabaseInfo.*/WorldDatabaseInfo = "'${WORLD_DB_HOST}';'${WORLD_DB_PORT}';'${WORLD_DB_USER}';'${WORLD_DB_PASS}';'${WORLD_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/CharacterDatabaseInfo.*/CharacterDatabaseInfo = "'${CHARACTERS_DB_HOST}';'${CHARACTERS_DB_PORT}';'${CHARACTERS_DB_USER}';'${CHARACTERS_DB_PASS}';'${CHARACTERS_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/LogsDatabaseInfo.*/LogsDatabaseInfo = "'${LOGS_DB_HOST}';'${LOGS_DB_PORT}';'${LOGS_DB_USER}';'${LOGS_DB_PASS}';'${LOGS_DB_NAME}'"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/LogsDir.*/LogsDir = "\/opt\/cmangos\/etc\/logs"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/DataDir.*/DataDir = "\/opt\/cmangos-data"/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/Ra.Enable \= 0/Ra.Enable \= 1/g' /opt/cmangos/etc/mangosd.conf
    sed -i 's/Console\.Enable \= 1/Console\.Enable \= 0/g' /opt/cmangos/etc/mangosd.conf

    # Create or update server in realmlist.
    sql_exec "LOGIN_DB" \
        "INSERT INTO realmlist (id,name,address,port) VALUES (${REALM_ID},'${REALM_NAME}','${REALM_ADDRESS}','${REALM_PORT}') ON DUPLICATE KEY UPDATE name='${REALM_NAME}', address='${REALM_ADDRESS}', port='${REALM_PORT}';" \
        "Updating realmlist with '${REALM_NAME}'"

    sed -i 's/RealmID.*/RealmID \= '${REALM_ID}'/g' /opt/cmangos/etc/mangosd.conf

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./mangosd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

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

# update_config "env_prefix" "config_file_path"
function update_config() {
	CONF=($(compgen -A variable | grep "$1"))

	for KEY in "${CONF[@]}"; do
		CONF_KEY=${KEY//${1}/}
		CONF_KEY=${CONF_KEY//_/.}
		sed -i 's/^\('${CONF_KEY}'\).*/\1 \= "'${!KEY//\//\\/}'"/ig' $2
	done
}

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900

if [ $? -eq 0 ]; then
    # Check if initialized
    if [ ! -f "/opt/cmangos/etc/.initialized" ]; then
		# Copy configs to volume
		copy_configs /opt/cmangos/configs/ /opt/cmangos/etc/

        sql_exec_admin "LOGIN_DB" \
            "CREATE DATABASE ${LOGIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
            "Create database ${LOGIN_DB_NAME}"

        sql_exec_admin "LOGIN_DB" \
            "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGIN_DB_NAME}.* TO ${LOGIN_DB_USER}@'%';" \
            "Grant all permissions to ${LOGIN_DB_USER} on the ${LOGIN_DB_NAME} database"

        # Import DB
        LOGIN_SQL=/opt/cmangos/sql/realmd.sql

        if [ "$INSTALL_FULL_DB" = TRUE ]; then
            wget "https://github.com/cmangos/${CMANGOS_CORE}-db/releases/download/latest/${CMANGOS_CORE}-all-db.zip"
            unzip ${CMANGOS_CORE}-all-db.zip

            LOGIN_SQL=/${CMANGOS_CORE}realmd.sql
        fi

        sql_file_exec "LOGIN_DB" $LOGIN_SQL "Installing login database"

        # Cleanup
        rm -f /$CMANGOS_CORE*.zip /$CMANGOS_CORE*.sql

        # Create .initialized file
        touch /opt/cmangos/etc/.initialized
    fi

    # Update realmd.conf
    sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${LOGIN_DB_HOST}';'${LOGIN_DB_PORT}';'${LOGIN_DB_USER}';'${LOGIN_DB_PASS}';'${LOGIN_DB_NAME}'"/g' /opt/cmangos/etc/realmd.conf

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./realmd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

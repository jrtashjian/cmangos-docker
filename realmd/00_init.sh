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

# Check for the existence of a database.
# sql_exec "env_var_prefix" "sql" "message"
function sql_check_db() {
	if [ ! -z "$2" ]; then echo -n "$2 ... "; fi

	local DBHOST="$1_HOST"
	local DBPORT="$1_PORT"
	local DBNAME="$1_NAME"
	local DBUSER="$1_ADMIN_USER"
	local DBPASS="$1_ADMIN_PASS"

	export MYSQL_PWD="${!DBPASS}"

	MYSQL_ERROR=$(mysql -h "${!DBHOST}" -P "${!DBPORT}" -u "${!DBUSER}" -s -N -D "${!DBNAME}" -e ";" 2>&1)

	if [[ $? != 0 ]]; then
		if [ ! -z "$2" ]; then
			echo "FAILED!"
			echo ">>> $MYSQL_ERROR"
		fi
		return 1
	else
		if [ ! -z "$2" ]; then echo "SUCCESS"; fi
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

# Execute SQL command.
# create_db_config "env_var_prefix" "output file" "message"
function create_db_config() {
	if [ ! -z "$3" ]; then echo -n "$3 ... "; fi

	local DBHOST="$1_HOST"
	local DBPORT="$1_PORT"
	local DBUSER="$1_USER"
	local DBPASS="$1_PASS"

    local config=()
    config+=("MYSQL_HOST=\"${!DBHOST}\"")
    config+=("MYSQL_PORT=\"${!DBPORT}\"")
    config+=("MYSQL_USERNAME=\"${!DBUSER}\"")
    config+=("MYSQL_PASSWORD=\"${!DBPASS}\"")

    config+=("WORLD_DB_NAME=\"${WORLD_DB_NAME}\"")
    config+=("REALM_DB_NAME=\"${LOGIN_DB_NAME}\"")
    config+=("CHAR_DB_NAME=\"${CHARACTERS_DB_NAME}\"")
    config+=("LOGS_DB_NAME=\"${LOGS_DB_NAME}\"")

    config+=("CORE_PATH=\"/opt/cmangos\"")
    config+=("LOCALES=\"NO\"")
    config+=("FORCE_WAIT=\"NO\"")
    config+=("AHBOT=\"YES\"")

    for line in "${config[@]}"; do
        echo $line
    done > $2

    if [[ $? == 0 ]]; then
		if [ ! -z "$3" ]; then echo "SUCCESS"; fi
	fi

	return 0
}

# Copy configs to volume
copy_configs /opt/cmangos/configs/ /opt/cmangos/etc/

create_db_config "LOGIN_DB" "/opt/database/login_db.config" "Creating login_db.config"

sed -n '/^## Main program/q;p' /opt/database/InstallFullDB.sh > /opt/database/CustomInstallFullDB.sh
chmod +x /opt/database/CustomInstallFullDB.sh
cat /opt/database/InstallFullDB.diff >> /opt/database/CustomInstallFullDB.sh

/wait-for-it.sh ${LOGIN_DB_HOST}:${LOGIN_DB_PORT} -t 900
if [ $? -eq 0 ]; then
	# Check if initialized
	sql_check_db "LOGIN_DB" "Checking for login database"
	if [ $? -ne 0 ]; then
		# Create DB
        sql_exec_admin "LOGIN_DB" \
            "CREATE DATABASE ${LOGIN_DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
            "Create database ${LOGIN_DB_NAME}"

        sql_exec_admin "LOGIN_DB" \
            "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGIN_DB_NAME}.* TO ${LOGIN_DB_USER}@'%';" \
            "Grant all permissions to ${LOGIN_DB_USER} on the ${LOGIN_DB_NAME} database"

		sql_file_exec "LOGIN_DB" /opt/cmangos/sql/base/realmd.sql "Installing login database"
	fi

	cd /opt/database
	/opt/database/CustomInstallFullDB.sh /opt/database/login_db.config LOGIN
else
    echo "[ERR] Timeout while waiting for ${LOGIN_DB_HOST}!";
    exit 1;
fi

# Update realmd.conf
REALMD_LOGINDATABASEINFO="${LOGIN_DB_HOST};${LOGIN_DB_PORT};${LOGIN_DB_USER};${LOGIN_DB_PASS};${LOGIN_DB_NAME}"
REALMD_LOGSDIR="/opt/cmangos/etc/logs"

update_config REALMD_ /opt/cmangos/etc/realmd.conf

# Ensure LogsDir exists
mkdir -p $REALMD_LOGSDIR

# Cleanup old initialize files
rm -f /opt/cmangos/etc/.login_db_initialized
rm -f /opt/cmangos/etc/.initialized

# Run CMaNGOS
cd /opt/cmangos/bin/
./realmd
exit 0;
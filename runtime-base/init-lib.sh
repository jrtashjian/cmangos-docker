#!/bin/bash

DEFAULT_DB_GRANTS="SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES"
WORLD_DB_EXTRA_GRANTS="EXECUTE, ALTER ROUTINE, CREATE ROUTINE"

init_base_db_env() {
	DB_HOST="${DB_HOST:=database}"
	DB_PORT="${DB_PORT:=3306}"
	DB_USER="${DB_USER:=mangos}"
	DB_PASS="${DB_PASS:=mangos}"
	DB_NAME="${DB_NAME:=mangos}"
	DB_ADMIN_USER="${DB_ADMIN_USER:=root}"
	DB_ADMIN_PASS="${DB_ADMIN_PASS:=mangos}"
}

# init_db_env "PREFIX" "default_db_name"
init_db_env() {
	local prefix="$1"
	local default_name="$2"

	_init_db_var "${prefix}_HOST" "$DB_HOST"
	_init_db_var "${prefix}_PORT" "$DB_PORT"
	_init_db_var "${prefix}_USER" "$DB_USER"
	_init_db_var "${prefix}_PASS" "$DB_PASS"
	_init_db_var "${prefix}_NAME" "$default_name"
	_init_db_var "${prefix}_ADMIN_USER" "$DB_ADMIN_USER"
	_init_db_var "${prefix}_ADMIN_PASS" "$DB_ADMIN_PASS"
}

_init_db_var() {
	local var_name="$1"
	local default="$2"

	if [ -z "${!var_name}" ]; then
		printf -v "$var_name" '%s' "$default"
	fi
}

# sql_exec_admin "env_var_prefix" "sql" "message"
sql_exec_admin() {
	sql_exec "$@" "admin"
}

# sql_exec "env_var_prefix" "sql" "message" "admin"
sql_exec() {
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

# sql_file_exec "prefix" "sql_file" "message"
sql_file_exec() {
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

# sql_check_db "env_var_prefix" "message"
sql_check_db() {
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
copy_configs() {
	find $1 -type f -path '*.dist' -exec bash -c 'FILE=$(basename ${0}); cp '$1'$FILE '$2'${FILE//.dist/}' {} \;
}

# update_config "env_prefix" "config_file_path"
update_config() {
	CONF=($(compgen -A variable | grep "$1"))

	for KEY in "${CONF[@]}"; do
		CONF_KEY=${KEY#${1}}
		CONF_KEY=${CONF_KEY//_/.}
		sed -i "s/\(${CONF_KEY}\)[[:space:]]*=.*/\1 = \"${!KEY//\//\\/}\"/ig" "$2"
	done
}

# create_db_config "env_var_prefix" "output file" "message"
create_db_config() {
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

ensure_custom_install_full_db() {
	sed -n '/^## Main program/q;p' /opt/database/InstallFullDB.sh > /opt/database/CustomInstallFullDB.sh
	chmod +x /opt/database/CustomInstallFullDB.sh
	cat /usr/share/cmangos/InstallFullDB.diff >> /opt/database/CustomInstallFullDB.sh
}

# wait_for_db "env_var_prefix"
wait_for_db() {
	local host_var="$1_HOST"
	local port_var="$1_PORT"

	/wait-for-it.sh "${!host_var}:${!port_var}" -t 900
	if [ $? -ne 0 ]; then
		echo "[ERR] Timeout while waiting for ${!host_var}!"
		exit 1
	fi
}

# ensure_database "prefix" "friendly_name" "base_sql" "config_file" "install_role" ["extra_grants"]
ensure_database() {
	local prefix="$1"
	local friendly_name="$2"
	local base_sql="$3"
	local config_file="$4"
	local install_role="$5"
	local extra_grants="${6:-}"

	local name_var="${prefix}_NAME"
	local user_var="${prefix}_USER"

	wait_for_db "$prefix"

	sql_check_db "$prefix" "Checking for ${friendly_name} database"
	if [ $? -ne 0 ]; then
		sql_exec_admin "$prefix" \
			"CREATE DATABASE ${!name_var} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;" \
			"Create database ${!name_var}"

		local grants="$DEFAULT_DB_GRANTS"
		if [ -n "$extra_grants" ]; then
			grants="${grants}, ${extra_grants}"
		fi

		sql_exec_admin "$prefix" \
			"GRANT ${grants} ON ${!name_var}.* TO ${!user_var}@'%';" \
			"Grant all permissions to ${!user_var} on the ${!name_var} database"

		sql_file_exec "$prefix" "$base_sql" "Installing ${friendly_name} database"
	fi

	cd /opt/database
	/opt/database/CustomInstallFullDB.sh "$config_file" "$install_role"
}

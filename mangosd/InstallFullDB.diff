source "$1"

try_set_mysql_path

if ! initialize; then
	exit 1
fi

if [[ "$2" == "CONTENT" ]]; then
	echo "Installing cmangos-world content"

	if ! apply_full_content_db; then
		exit 1
	fi
fi

if [[ "$2" == "WORLD" ]]; then
	echo "Installing cmangos-world database"

    get_current_db_version "$WORLD_DB_NAME" "db_version"
    DB_WORLDDB_VERSION="$CURRENT_DB_VERSION"
    DB_LAST_CONTENT_VERSION_UPDATE="$CURRENT_LAST_CONTENT_DB_VERSION"
    STATUS_WORLD_DB_FOUND=true

	if ! apply_world_db_core_update; then
		exit 1
	fi
fi

if [[ "$2" == "CHARACTERS" ]]; then
	echo "Updating cmangos-characters database"

    get_current_db_version "$CHAR_DB_NAME" "character_db_version"
    DB_CHARDB_VERSION="$CURRENT_DB_VERSION"
    STATUS_CHAR_DB_FOUND=true

	if ! apply_char_db_core_update; then
		exit 1
	fi
fi

if [[ "$2" == "LOGS" ]]; then
	echo "Updating cmangos-logs database"

    get_current_db_version "$LOGS_DB_NAME" "logs_db_version"
    DB_LOGSDB_VERSION="$CURRENT_DB_VERSION"
    STATUS_LOGS_DB_FOUND=true

	if ! apply_logs_db_core_update; then
		exit 1
	fi
fi

if [[ "$2" == "LOGIN" ]]; then
	echo "Updating cmangos-login database"

	get_current_db_version "$REALM_DB_NAME" "realmd_db_version"
    DB_REALMDB_VERSION="$CURRENT_DB_VERSION"
    STATUS_REALM_DB_FOUND=true

	if ! apply_realm_db_core_update; then
		exit 1
	fi
fi
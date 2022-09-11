#!/bin/bash

# Environment Vars:
# - REALMD_DB
# - MYSQL_ROOT_PASSWORD
# - MYSQL_USER
# - MYSQL_PASSWORD
# - DB_SERVER

/wait-for-it.sh ${DB_SERVER}:3306 -t 900

if [ $? -eq 0 ]; then
    # Check if intialized
    if [ ! -f "/opt/cmangos/etc/.intialized" ]; then
		# Copy configs to volume
		cp /opt/cmangos/configs/* /opt/cmangos/etc/
        mv -v /opt/cmangos/etc/realmd.conf.dist /opt/cmangos/etc/realmd.conf

        # Configure DB Settings
        sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${DB_SERVER}';3306;'${MYSQL_USER}';'${MYSQL_PASSWORD}';'${REALMD_DB}'"/g' /opt/cmangos/etc/realmd.conf

        # Create DB
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE ${REALMD_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${REALMD_DB}.* TO ${MYSQL_USER}@'%';"
        mysql -h $DB_SERVER -u $MYSQL_USER -p$MYSQL_PASSWORD $REALMD_DB < /opt/cmangos/sql/realmd.sql

        # Create .initialized file
        touch /opt/cmangos/etc/.intialized
    fi

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./realmd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${DB_SERVER}!";
    exit 1;
fi

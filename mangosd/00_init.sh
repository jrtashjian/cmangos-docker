#!/bin/bash

# Environment Vars:
# - REALMD_SERVER
# - REALMD_DB
# - WORLD_DB
# - CHARACTER_DB
# - LOGS_DB
# - MYSQL_ROOT_PASSWORD
# - MYSQL_USER
# - MYSQL_PASSWORD
# - DB_SERVER

/wait-for-it.sh "${REALMD_SERVER}" -t 900

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
        sed -i 's/LoginDatabaseInfo.*/LoginDatabaseInfo = "'${DB_SERVER}';3306;'${MYSQL_USER}';'${MYSQL_PASSWORD}';'${REALMD_DB}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/WorldDatabaseInfo.*/WorldDatabaseInfo = "'${DB_SERVER}';3306;'${MYSQL_USER}';'${MYSQL_PASSWORD}';'${WORLD_DB}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/CharacterDatabaseInfo.*/CharacterDatabaseInfo = "'${DB_SERVER}';3306;'${MYSQL_USER}';'${MYSQL_PASSWORD}';'${CHARACTER_DB}'"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/LogsDatabaseInfo.*/LogsDatabaseInfo = "'${DB_SERVER}';3306;'${MYSQL_USER}';'${MYSQL_PASSWORD}';'${LOGS_DB}'"/g' /opt/cmangos/etc/mangosd.conf

        # Additional configuration
        sed -i 's/LogsDir.*/LogsDir = "\/opt\/cmangos\/etc\/logs"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/DataDir.*/DataDir = "\/opt\/cmangos-data"/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/Ra.Enable \= 0/Ra.Enable \= 1/g' /opt/cmangos/etc/mangosd.conf
        sed -i 's/Console\.Enable \= 1/Console\.Enable \= 0/g' /opt/cmangos/etc/mangosd.conf

        # Create DB
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE ${WORLD_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE ${CHARACTER_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE ${LOGS_DB} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"

        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${WORLD_DB}.* TO ${MYSQL_USER}@'%';"
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${CHARACTER_DB}.* TO ${MYSQL_USER}@'%';"
        mysql -h $DB_SERVER -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER, LOCK TABLES, CREATE TEMPORARY TABLES ON ${LOGS_DB}.* TO ${MYSQL_USER}@'%';"

        mysql -h $DB_SERVER -u $MYSQL_USER -p$MYSQL_PASSWORD $WORLD_DB < /opt/cmangos/sql/mangos.sql
        mysql -h $DB_SERVER -u $MYSQL_USER -p$MYSQL_PASSWORD $CHARACTER_DB < /opt/cmangos/sql/characters.sql
        mysql -h $DB_SERVER -u $MYSQL_USER -p$MYSQL_PASSWORD $LOGS_DB < /opt/cmangos/sql/logs.sql

        # Add required data for an empty world
        mysql -h $DB_SERVER -u $MYSQL_USER -p$MYSQL_PASSWORD $WORLD_DB < /opt/cmangos/sql/initial-tables.sql

        # Create .initialized file
        touch /opt/cmangos/etc/.intialized
    fi

	# Run CMaNGOS
	cd /opt/cmangos/bin/
	./mangosd
	exit 0;
else
    echo "[ERR] Timeout while waiting for ${DB_SERVER}!";
    exit 1;
fi

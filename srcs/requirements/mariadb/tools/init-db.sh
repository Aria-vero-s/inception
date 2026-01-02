#!/usr/bin/env bash
set -e


# start mysqld in background
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld /var/lib/mysql || true


# initialize db if empty
if [ ! -d "/var/lib/mysql/mysql" ]; then
echo "Initializing MariaDB data directory"
mysql_install_db --user=mysql --datadir=/var/lib/mysql


# start server
mysqld_safe --datadir=/var/lib/mysql &
pid=$!


# Wait for server to be ready
until mysqladmin ping --silent; do
sleep 1
done


# Read secrets
DB_ROOT_PASS=$(cat /run/secrets/db_root_password 2>/dev/null || echo "rootpass")
DB_PASS=$(cat /run/secrets/db_password 2>/dev/null || echo "wppass")


mysql -u root <<-EOSQL
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
FLUSH PRIVILEGES;
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOSQL


echo "Database initialized"


# stop temporary server
mysqladmin -u root -p"${DB_ROOT_PASS}" shutdown || true
wait $pid || true
fi


# finally run mysqld in foreground
exec mysqld --datadir=/var/lib/mysql --user=mysql
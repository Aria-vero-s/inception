#!/usr/bin/env bash
set -e


# If WordPress isn't installed in the volume, extract it
if [ ! -f /var/www/html/index.php ]; then
    echo "Installing WordPress to volume..."
    wget -q https://wordpress.org/latest.tar.gz -O /tmp/wordpress.tar.gz
    tar -xzf /tmp/wordpress.tar.gz -C /tmp
    cp -r /tmp/wordpress/* /var/www/html/
    rm -rf /tmp/wordpress /tmp/wordpress.tar.gz
fi

# ensure the www-data user owns the files
chown -R www-data:www-data /var/www/html || true


# If wp-config.php doesn't exist, create it using env vars
if [ ! -f /var/www/html/wp-config.php ]; then
echo "Generating wp-config.php"
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
# Replace DB placeholders: keep it simple — WordPress will be configured at first visit or with WP-CLI
sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/g" /var/www/html/wp-config.php
sed -i "s/username_here/${WORDPRESS_DB_USER}/g" /var/www/html/wp-config.php
sed -i "s/password_here/$(cat /run/secrets/db_password 2>/dev/null || echo '')/g" /var/www/html/wp-config.php
sed -i "s/'localhost'/'${WORDPRESS_DB_HOST}'/g" /var/www/html/wp-config.php
fi


# Start php-fpm in foreground (find the actual binary)
PHP_FPM=$(command -v php-fpm8.4 || command -v php-fpm8.2 || command -v php-fpm)
exec $PHP_FPM -F
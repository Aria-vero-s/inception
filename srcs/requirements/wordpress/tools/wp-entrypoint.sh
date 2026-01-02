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

# If wp-config.php doesn't exist, create it
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Generating wp-config.php"
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/g" /var/www/html/wp-config.php
    sed -i "s/username_here/${WORDPRESS_DB_USER}/g" /var/www/html/wp-config.php
    sed -i "s/password_here/$(cat /run/secrets/db_password 2>/dev/null || echo '')/g" /var/www/html/wp-config.php
    sed -i "s/'localhost'/'${WORDPRESS_DB_HOST}'/g" /var/www/html/wp-config.php
fi

# Wait for database to be ready (non-blocking setup)
RETRIES=30
while ! mysqladmin ping -h "${WORDPRESS_DB_HOST}" -u "${WORDPRESS_DB_USER}" -p"$(cat /run/secrets/db_password 2>/dev/null)" 2>/dev/null && [ $RETRIES -gt 0 ]; do
    RETRIES=$((RETRIES - 1))
    sleep 1
done

# Check if WordPress is already installed and set it up if needed
if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="WordPress" \
        --admin_user="siteadmin" \
        --admin_email="admin@${DOMAIN_NAME}" \
        --admin_password="$(cat /run/secrets/wp_admin_password 2>/dev/null || echo 'password')" \
        --allow-root
    
    wp user create \
        --path=/var/www/html \
        editor editor@${DOMAIN_NAME} \
        --role=editor \
        --user_pass="$(cat /run/secrets/wp_admin_password 2>/dev/null || echo 'password')" \
        --allow-root || true
fi

# Start PHP-FPM in foreground (PID 1)
exec php-fpm8.4 -F
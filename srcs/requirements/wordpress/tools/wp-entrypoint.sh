#!/usr/bin/env bash
set -e

# If WordPress isn't installed in the volume, extract it
if [ ! -f /var/www/html/index.php ]; then
    echo "Installing WordPress to volume..."
    wget -q https://wordpress.org/wordpress-6.4.2.tar.gz -O /tmp/wordpress.tar.gz
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
while [ $RETRIES -gt 0 ]; do
    if php -r "mysqli_connect('${WORDPRESS_DB_HOST}', '${WORDPRESS_DB_USER}', file_get_contents('/run/secrets/db_password'));" 2>/dev/null; then
        break
    fi
    RETRIES=$((RETRIES - 1))
    sleep 1
done

# Check if WordPress is already installed and set it up if needed
if ! wp core is-installed --path=/var/www/html --allow-root 2>/dev/null; then
    WP_ADMIN_PASS=$(cat /run/secrets/wp_admin_password 2>/dev/null || echo 'changeme')
    WP_USER_PASS=$(cat /run/secrets/wp_user_password 2>/dev/null || echo 'changeme')
    
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE:-Inception}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --admin_password="${WP_ADMIN_PASS}" \
        --allow-root
    
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
        --path=/var/www/html \
        --role=author \
        --user_pass="${WP_USER_PASS}" \
        --allow-root || true

    # Disable comment moderation so comments appear immediately
    wp option update comment_moderation 0 --path=/var/www/html --allow-root
    wp option update comment_previously_approved 0 --path=/var/www/html --allow-root
    wp option update moderation_notify 0 --path=/var/www/html --allow-root
    
    echo "WordPress configured: comments don't require approval"
fi

# Start PHP-FPM in foreground (PID 1)
exec php-fpm8.2 -F
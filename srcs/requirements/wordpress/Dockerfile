FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    tar \
    php-fpm \
    php-mysql \
    php-xml \
    php-mbstring \
    php-gd \
    php-cli \
  && rm -rf /var/lib/apt/lists/*

# Install WP-CLI
RUN wget -q https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -O /usr/local/bin/wp \
  && chmod +x /usr/local/bin/wp

# Create webroot and permissions
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

# Configure PHP-FPM to listen on TCP port 9000
COPY conf/php-fpm.conf /etc/php/8.2/fpm/php-fpm.conf
COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf

WORKDIR /var/www/html

COPY tools/wp-entrypoint.sh /usr/local/bin/wp-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-entrypoint.sh

EXPOSE 9000
CMD ["/usr/local/bin/wp-entrypoint.sh"]

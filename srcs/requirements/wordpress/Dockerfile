FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    tar \
    unzip \
    php-fpm \
    php-mysql \
    php-xml \
    php-mbstring \
    php-gd \
  && rm -rf /var/lib/apt/lists/*

# Create webroot and permissions
RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html

# Configure PHP-FPM to listen on TCP port 9000
COPY conf/www.conf /etc/php/8.4/fpm/pool.d/www.conf

WORKDIR /var/www/html

# Download WordPress during build if not present
RUN wget -q https://wordpress.org/latest.zip -O /tmp/wordpress.zip \
  && unzip /tmp/wordpress.zip -d /tmp \
  && mv /tmp/wordpress/* /var/www/html/ \
  && rm -rf /tmp/wordpress /tmp/wordpress.zip

COPY tools/wp-entrypoint.sh /usr/local/bin/wp-entrypoint.sh
RUN chmod +x /usr/local/bin/wp-entrypoint.sh

# Ensure php-fpm runs as foreground process
EXPOSE 9000
CMD ["/usr/local/bin/wp-entrypoint.sh"]

FROM debian:bookworm-slim

ARG DOMAIN_NAME=asaulnie.42.fr

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Remove default site
RUN rm -f /etc/nginx/sites-enabled/default || true

# Create SSL directory and generate self-signed certificate
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/server.key \
    -out /etc/nginx/ssl/server.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}" && \
    chmod 600 /etc/nginx/ssl/server.key

COPY conf/default.conf /etc/nginx/conf.d/default.conf.template

# Substitute DOMAIN_NAME in nginx config
RUN sed -i "s/DOMAIN_NAME_PLACEHOLDER/${DOMAIN_NAME}/g" /etc/nginx/conf.d/default.conf.template \
    && mv /etc/nginx/conf.d/default.conf.template /etc/nginx/conf.d/default.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]
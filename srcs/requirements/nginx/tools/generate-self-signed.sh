#!/usr/bin/env bash
set -e
mkdir -p /home/asaulnie/Inception/srcs/requirements/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout /home/asaulnie/Inception/srcs/requirements/nginx/ssl/server.key \
-out /home/asaulnie/Inception/srcs/requirements/nginx/ssl/server.crt \
-subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}"


chmod 600 /home/asaulnie/Inception/srcs/requirements/nginx/ssl/server.key
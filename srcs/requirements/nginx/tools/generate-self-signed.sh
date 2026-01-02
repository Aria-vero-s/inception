#!/usr/bin/env bash
set -e
mkdir -p $(pwd)/../ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
-keyout $(pwd)/../ssl/server.key \
-out $(pwd)/../ssl/server.crt \
-subj "/C=FR/ST=Paris/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}"


chmod 600 $(pwd)/../ssl/server.key
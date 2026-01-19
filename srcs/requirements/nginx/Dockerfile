FROM debian:stable-slim

ARG DOMAIN_NAME=asaulnie.42.fr

RUN apt-get update && apt-get install -y --no-install-recommends \
nginx \
openssl \
&& rm -rf /var/lib/apt/lists/*


# Remove default site
RUN rm -f /etc/nginx/sites-enabled/default || true


COPY conf/default.conf /etc/nginx/conf.d/default.conf

# Generate SSL certificate
COPY tools/generate-self-signed.sh /tmp/generate-self-signed.sh
RUN chmod +x /tmp/generate-self-signed.sh && DOMAIN_NAME=${DOMAIN_NAME} /tmp/generate-self-signed.sh

# Expose only 443
EXPOSE 443


CMD ["nginx", "-g", "daemon off;"]
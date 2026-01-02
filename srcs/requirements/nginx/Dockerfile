FROM debian:stable-slim


RUN apt-get update && apt-get install -y --no-install-recommends \
nginx \
openssl \
&& rm -rf /var/lib/apt/lists/*


# Remove default site
RUN rm -f /etc/nginx/sites-enabled/default || true


COPY conf/default.conf /etc/nginx/conf.d/default.conf


# Expose only 443
EXPOSE 443


CMD ["nginx", "-g", "daemon off;"]
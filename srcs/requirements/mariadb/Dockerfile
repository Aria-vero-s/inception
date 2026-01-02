FROM debian:stable-slim


ENV DEBIAN_FRONTEND=noninteractive


RUN apt-get update && apt-get install -y --no-install-recommends \
mariadb-server \
mariadb-client \
&& rm -rf /var/lib/apt/lists/*


COPY conf/my.cnf /etc/mysql/my.cnf
COPY tools/init-db.sh /usr/local/bin/init-db.sh
RUN chmod +x /usr/local/bin/init-db.sh


VOLUME ["/var/lib/mysql"]


EXPOSE 3306


CMD ["/usr/local/bin/init-db.sh"]
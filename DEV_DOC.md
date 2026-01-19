# Developer Documentation

## Project Architecture

This Inception project implements a multi-container Docker infrastructure following Docker best practices and 42 School requirements.

### Architecture Overview

```
                    ┌─────────────────┐
                    │   Host System   │
                    │  asaulnie.42.fr │
                    └────────┬────────┘
                             │ :443 (HTTPS)
                    ┌────────▼────────┐
                    │     NGINX       │
                    │   (TLS 1.2/1.3) │
                    └────────┬────────┘
                             │ :9000 (FastCGI)
                    ┌────────▼────────┐
                    │   WordPress     │
                    │   + PHP-FPM     │
                    └────────┬────────┘
                             │ :3306 (MySQL)
                    ┌────────▼────────┐
                    │    MariaDB      │
                    │   (Database)    │
                    └─────────────────┘
                All connected via inception_network (bridge)
```

---

## Environment Setup from Scratch

### 1. Prerequisites

Install required packages:
```bash
sudo apt update
sudo apt install docker.io docker-compose make -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

**Important**: Log out and back in after adding user to docker group.

### 2. Project Structure

```
Inception/
├── Makefile                          # Build and deployment automation
├── .gitignore                        # Exclude secrets from git
├── secrets/                          # Sensitive credentials (not in git)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── .env                          # Environment variables
    ├── docker-compose.yml            # Service orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/default.conf
        │   ├── ssl/                  # Auto-generated certificates
        │   └── tools/generate-self-signed.sh
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/www.conf
        │   └── tools/wp-entrypoint.sh
        └── mariadb/
            ├── Dockerfile
            ├── conf/my.cnf
            └── tools/init-db.sh
```

### 3. Create Secret Files

```bash
mkdir -p secrets
echo "your_db_password" > secrets/db_password.txt
echo "your_root_password" > secrets/db_root_password.txt
echo "your_admin_password" > secrets/wp_admin_password.txt
chmod 600 secrets/*.txt
```

### 4. Configure Environment

Edit `srcs/.env`:
```bash
DOMAIN_NAME=asaulnie.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
HOST_DATA_DIR=/home/asaulnie/data
```

### 5. Configure Domain Resolution

```bash
echo "127.0.0.1 asaulnie.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching

### Using Makefile (Recommended)

```bash
# Build images and start containers
make all

# Build only (no start)
make build

# Start containers (assumes already built)
make up

# Stop containers
make stop

# Stop and remove containers + volumes
make down

# Full cleanup
make clean
```

### Manual Docker Compose Commands

```bash
# Build without cache
docker compose -f srcs/docker-compose.yml build --no-cache

# Start in detached mode
docker compose -f srcs/docker-compose.yml up -d

# Stop services
docker compose -f srcs/docker-compose.yml stop

# Remove everything
docker compose -f srcs/docker-compose.yml down --volumes --remove-orphans
```

---

## Docker Container Management

### Inspect Running Containers

```bash
# List all containers
docker ps -a

# View logs
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Execute commands inside containers
docker exec -it nginx /bin/bash
docker exec -it wordpress /bin/bash
docker exec mariadb mysql -u root -p
```

### Network Inspection

```bash
# List networks
docker network ls

# Inspect the inception network
docker network inspect srcs_inception_network

# Check container IPs
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nginx
```

### Volume Management

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect srcs_mysql_data
docker volume inspect srcs_wordpress_data

# Check volume mount points
docker inspect -f '{{json .Mounts}}' wordpress | jq
```

---

## Data Persistence

### Volume Locations

Data is stored in `/home/asaulnie/data/`:

- **MariaDB data**: `/home/asaulnie/data/mysql/`
  - Database files
  - InnoDB data
  - Binary logs

- **WordPress files**: `/home/asaulnie/data/wordpress/`
  - Core WordPress files
  - Themes and plugins
  - Uploaded media
  - wp-config.php

### Backup Strategy

```bash
# Backup database
docker exec mariadb mysqldump \
  -u root \
  -p$(cat secrets/db_root_password.txt) \
  wordpress > backup-$(date +%Y%m%d).sql

# Backup WordPress files
tar -czf wordpress-backup-$(date +%Y%m%d).tar.gz \
  /home/asaulnie/data/wordpress/

# Restore database
docker exec -i mariadb mysql \
  -u root \
  -p$(cat secrets/db_root_password.txt) \
  wordpress < backup-20260102.sql
```

---

## Service Configuration Details

### NGINX

- **Base Image**: `debian:stable-slim`
- **Port**: 443 (HTTPS only)
- **TLS**: TLSv1.2 and TLSv1.3
- **FastCGI**: Proxies PHP requests to wordpress:9000
- **SSL**: Self-signed certificate (generated during build/runtime)

**Configuration**: [srcs/requirements/nginx/conf/default.conf](srcs/requirements/nginx/conf/default.conf)

### WordPress + PHP-FPM

- **Base Image**: `debian:stable-slim`
- **PHP Version**: 8.4 (from Debian stable)
- **Listen**: Port 9000 (FastCGI)
- **Entrypoint**: Custom script that:
  - Installs WordPress if not present
  - Generates wp-config.php
  - Sets correct permissions
  - Starts PHP-FPM in foreground

**Entry Script**: [srcs/requirements/wordpress/tools/wp-entrypoint.sh](srcs/requirements/wordpress/tools/wp-entrypoint.sh)

### MariaDB

- **Base Image**: `debian:stable-slim`
- **Port**: 3306 (internal only)
- **Initialization**: Custom script that:
  - Initializes database if empty
  - Creates database and users
  - Sets up permissions
  - Runs mysqld in foreground (PID 1)

**Init Script**: [srcs/requirements/mariadb/tools/init-db.sh](srcs/requirements/mariadb/tools/init-db.sh)

---

## Docker Secrets vs Environment Variables

This project uses **Docker Secrets** for sensitive data:

### Why Secrets?

- ✅ **More secure**: Not visible in `docker inspect`
- ✅ **Encrypted**: In Swarm mode (though we use file-based secrets)
- ✅ **Separate from code**: No risk of committing passwords
- ✅ **Read-only mounts**: Available at `/run/secrets/` inside containers

### Environment Variables

Used for **non-sensitive configuration**:
- `DOMAIN_NAME`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `HOST_DATA_DIR`

---

## Docker Network vs Host Network

### Bridge Network (Used in this project)

```yaml
networks:
  inception_network:
    driver: bridge
```

**Advantages**:
- ✅ **Isolation**: Services isolated from host
- ✅ **DNS**: Automatic service name resolution (nginx → wordpress → mariadb)
- ✅ **Security**: Services not directly exposed to host network
- ✅ **Portability**: Works everywhere

**vs Host Network**:
- ❌ **Less isolated**: Containers share host network stack
- ❌ **Port conflicts**: Can't run multiple instances
- ❌ **Security**: More attack surface

---

## Docker Volumes vs Bind Mounts

### Volumes (Used in this project)

```yaml
volumes:
  - ${HOST_DATA_DIR}/mysql:/var/lib/mysql
```

**Advantages**:
- ✅ **Docker-managed**: Better performance on some systems
- ✅ **Explicit location**: Easy to backup at known path
- ✅ **Permissions**: Automatically handled
- ✅ **Portable**: Same behavior across systems

**vs Anonymous Volumes**:
- Named volumes with specific host paths give us control over data location

---

## Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Resource Usage** | Heavy (full OS per VM) | Lightweight (shared kernel) |
| **Startup Time** | Minutes | Seconds |
| **Isolation** | Complete (hypervisor) | Process-level |
| **Portability** | Large image files | Small, layered images |
| **Use Case** | Strong isolation needed | Microservices, dev environments |

**This Project**: Runs inside a VM (Debian) but uses Docker containers for services.

---

## Development Workflow

### Making Changes

1. **Modify Dockerfile or configs**
2. **Rebuild specific service**:
   ```bash
   docker compose -f srcs/docker-compose.yml build nginx
   ```
3. **Restart service**:
   ```bash
   docker compose -f srcs/docker-compose.yml up -d nginx
   ```

### Debugging

```bash
# Check container logs in real-time
docker logs -f --tail 100 wordpress

# Execute commands for debugging
docker exec wordpress ps aux
docker exec wordpress ls -la /var/www/html

# Test network connectivity
docker exec wordpress ping mariadb
docker exec wordpress nc -zv mariadb 3306
```

### Testing SSL/TLS

```bash
# Check certificate
echo | openssl s_client -connect asaulnie.42.fr:443 2>/dev/null | openssl x509 -noout -text

# Test TLS versions
openssl s_client -connect asaulnie.42.fr:443 -tls1_2
openssl s_client -connect asaulnie.42.fr:443 -tls1_3
```

---

## Compliance with Requirements

✅ **No ready-made images**: All Dockerfiles built from Alpine/Debian base
✅ **No :latest tag**: Using `debian:stable-slim`
✅ **No passwords in Dockerfiles**: Using Docker secrets
✅ **No infinite loops**: All services run proper daemons in foreground
✅ **Restart policy**: `restart: unless-stopped` on all services
✅ **Custom network**: `inception_network` (bridge driver)
✅ **Port 443 only**: NGINX is the only entrypoint
✅ **TLS 1.2/1.3**: Configured in NGINX
✅ **Volumes**: Two volumes for database and WordPress files
✅ **PID 1 compliance**: All CMD/ENTRYPOINT run main process in foreground

---

## Common Development Issues

### Port already in use
```bash
sudo lsof -i :443
sudo systemctl stop apache2  # if Apache is running
```

### Permission denied on volumes
```bash
sudo chown -R $(id -u):$(id -g) /home/asaulnie/data/
```

### Database connection errors
Check that MariaDB is fully initialized before WordPress starts:
```bash
docker logs mariadb | grep "ready for connections"
```

### Clean rebuild
```bash
make down
make clean
docker system prune -a --volumes  # WARNING: removes ALL Docker data
make all
```

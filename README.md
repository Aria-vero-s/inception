# Inception

*This project has been created as part of the 42 curriculum by asaulnie.*

## Description

**Inception** is a system administration project that focuses on Docker containerization and orchestration. The goal is to create a small infrastructure composed of different services using Docker Compose, with each service running in its own dedicated container built from a custom Dockerfile.

The project implements a WordPress website with the following architecture:
- **NGINX** with TLSv1.2/1.3 as the web server and reverse proxy
- **WordPress** with PHP-FPM for content management
- **MariaDB** as the database backend

All services communicate through a Docker network, use volumes for persistent data storage, and are configured to restart automatically.

## Instructions

### Prerequisites

- Debian 12 (bookworm) or compatible Linux distribution
- Docker and Docker Compose installed
- `make` utility

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/aria-vero-s/inception.git
   cd inception
   ```

2. **Create the secrets directory and files**:
   ```bash
   mkdir -p secrets
   echo "your_admin_password" > secrets/wp_admin_password.txt
   echo "your_user_password" > secrets/wp_user_password.txt
   echo "your_db_password" > secrets/db_password.txt
   echo "your_db_root_password" > secrets/db_root_password.txt
   ```

3. **Create the environment file**:
   ```bash
   cat > srcs/.env << 'EOF'
   DOMAIN_NAME=asaulnie.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   WP_ADMIN_USER=asaulnie
   WP_ADMIN_EMAIL=asaulnie@student.42.fr
   WP_TITLE=Inception
   WP_USER=johndoe
   WP_USER_EMAIL=johndoe@student.42.fr
   HOST_DATA_DIR=/home/asaulnie/data
   EOF
   ```

4. **Add domain to /etc/hosts**:
   ```bash
   sudo sh -c 'echo "127.0.0.1 asaulnie.42.fr" >> /etc/hosts'
   ```

5. **Build and launch the infrastructure**:
   ```bash
   make
   ```

### Available Commands

- `make` or `make all` - Create volumes, build images, and start containers
- `make build` - Build Docker images
- `make up` - Start containers in detached mode
- `make down` - Stop and remove containers
- `make stop` - Stop running containers
- `make start` - Start stopped containers
- `make restart` - Restart containers
- `make clean` - Stop and remove containers with volumes
- `make fclean` - Complete cleanup (removes all Docker resources and project directory)

### Access

Once running, access the services:
- **WordPress site**: https://asaulnie.42.fr
- **WordPress admin**: https://asaulnie.42.fr/wp-admin

**User credentials** (from secrets files):
- Admin: `asaulnie` / (see `secrets/wp_admin_password.txt`)
- User: `johndoe` / (see `secrets/wp_user_password.txt`)

## Resources

### Documentation
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [WordPress Codex](https://codex.wordpress.org/)
- [WP-CLI Documentation](https://wp-cli.org/)

### Tutorials
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Docker Networking](https://docs.docker.com/network/)
- [Docker Volumes](https://docs.docker.com/storage/volumes/)

### AI Usage
AI assistance (GitHub Copilot) was used for:
- **Code review and debugging**: Identifying issues in Dockerfiles, shell scripts, and configuration files
- **Documentation**: Structuring and writing clear technical documentation
- **Best practices**: Suggesting Docker security practices and optimization techniques
- **Shell scripting**: Assistance with bash scripts for WordPress and MariaDB initialization
- **Troubleshooting**: Debugging network connectivity and volume persistence issues

The core architecture, design decisions, and implementation were done independently, with AI serving as a consultation and verification tool.

## Project Description

### Overview

This project demonstrates the use of **Docker** to create a containerized infrastructure. Each service (NGINX, WordPress, MariaDB) runs in its own isolated container, built from a custom Dockerfile based on the penultimate stable version of Debian.

### Main Design Choices

#### 1. Container Architecture
- **One process per container**: Each container runs a single main service (PID 1)
- **Custom Dockerfiles**: No use of pre-built images from Docker Hub (except base Debian)
- **Entrypoint scripts**: Custom initialization scripts for MariaDB and WordPress
- **No infinite loops**: Services run in foreground mode (daemon off)

#### 2. Security
- **Docker secrets**: Sensitive data (passwords) stored as Docker secrets, not in environment variables
- **TLS encryption**: NGINX configured with TLSv1.2/1.3 using self-signed certificates
- **Minimal base images**: Using Debian slim images to reduce attack surface
- **Non-root processes**: Services run as dedicated users (www-data, mysql)

#### 3. Persistence
- **Named volumes**: Database and WordPress files stored in Docker volumes
- **Volume mapping**: Volumes mapped to host directory for easier backup
- **Automatic restart**: Containers configured to restart on failure

#### 4. Networking
- **Custom bridge network**: Services communicate via a dedicated Docker network
- **Service discovery**: Containers access each other by service name (DNS resolution)
- **Port exposure**: Only NGINX exposes port 443 to the host

### Technical Comparisons

#### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|------------------|-------------------|
| **Isolation** | Full OS isolation with hypervisor | Process-level isolation with shared kernel |
| **Resource Usage** | High (GB of RAM per VM) | Low (MB of RAM per container) |
| **Startup Time** | Minutes (full OS boot) | Seconds (process start) |
| **Portability** | Limited (large image sizes) | High (small, layered images) |
| **Use Case** | Complete OS environments | Application deployment |

**Choice for Inception**: Docker is ideal for this project because we need lightweight, portable services that share the host kernel while remaining isolated. VMs would be overkill for running simple services like NGINX and MariaDB.

#### Secrets vs Environment Variables

| Aspect | Docker Secrets | Environment Variables |
|--------|----------------|----------------------|
| **Security** | Encrypted in transit and at rest | Visible in `docker inspect` and process list |
| **Storage** | In-memory filesystem (`/run/secrets/`) | Environment of the process |
| **Rotation** | Can be updated without rebuilding | Require container restart |
| **Best For** | Passwords, API keys, certificates | Configuration, non-sensitive settings |

**Choice for Inception**: Secrets are used for all passwords (DB root, DB user, WordPress passwords) because they are more secure and never appear in environment variables or logs. The `.env` file is used only for non-sensitive configuration.

#### Docker Network vs Host Network

| Aspect | Docker Bridge Network | Host Network |
|--------|----------------------|--------------|
| **Isolation** | Network namespace isolation | Shares host network stack |
| **Service Discovery** | Built-in DNS resolution | Manual IP management |
| **Port Conflicts** | Containers can use same ports | Ports must be unique on host |
| **Security** | Better isolation | Direct host exposure |
| **Performance** | Slight overhead (NAT) | Native performance |

**Choice for Inception**: A custom bridge network (`inception_network`) provides:
- DNS-based service discovery (containers find each other by name)
- Network isolation from other containers
- Controlled port exposure (only NGINX:443 is accessible from outside)

#### Docker Volumes vs Bind Mounts

| Aspect | Docker Volumes | Bind Mounts |
|--------|----------------|-------------|
| **Management** | Docker manages storage location | User specifies exact host path |
| **Portability** | Portable across systems | Path-dependent |
| **Permissions** | Docker handles permissions | Must match host/container UIDs |
| **Backup** | `docker volume` commands | Standard filesystem tools |
| **Performance** | Optimized by Docker | Direct filesystem access |

**Choice for Inception**: We use **named volumes** mapped to a specific host directory (`/home/asaulnie/data`):
```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/asaulnie/data/mysql
```

This hybrid approach provides:
- Docker volume management (naming, lifecycle)
- Easy host access for backups
- Clear data persistence location
- Evaluation-friendly structure (data visible in `/home/$USER/data`)

### Sources Included

- **Dockerfiles**: Custom build files for each service (NGINX, WordPress, MariaDB)
- **Configuration files**:
  - `nginx/conf/default.conf` - NGINX server configuration with TLS
  - `mariadb/conf/my.cnf` - MariaDB server configuration
  - `wordpress/conf/php-fpm.conf` & `www.conf` - PHP-FPM configuration
- **Initialization scripts**:
  - `mariadb/tools/init-db.sh` - Database initialization
  - `wordpress/tools/wp-entrypoint.sh` - WordPress setup with WP-CLI
- **Orchestration**: `docker-compose.yml` - Service definitions and dependencies
- **Secrets**: Password files (not in repository, created at setup)
- **Environment**: `.env` file (not in repository, created at setup)

## Project Structure

```
inception/
├── Makefile                    # Build and management commands
├── README.md                   # This file
├── secrets/                    # Sensitive data (git-ignored)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                    # Environment variables (git-ignored)
    ├── docker-compose.yml      # Service orchestration
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── my.cnf
        │   └── tools/
        │       └── init-db.sh
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── default.conf
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            │   ├── php-fpm.conf
            │   └── www.conf
            └── tools/
                └── wp-entrypoint.sh
```

## License

This project is part of the 42 school curriculum and is for educational purposes.

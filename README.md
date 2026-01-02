*This project has been created as part of the 42 curriculum by asaulnie.*

# Inception

A system administration project that builds a complete web infrastructure using Docker containers, featuring NGINX, WordPress, and MariaDB services.

## Description

**Inception** is a Docker-based infrastructure project that deploys a WordPress website with proper containerization, security, and best practices. The project demonstrates understanding of:

- **Containerization**: Building custom Docker images from scratch
- **Service Orchestration**: Using Docker Compose to manage multi-container applications
- **Security**: Implementing TLS/SSL encryption and secrets management
- **Networking**: Configuring isolated Docker networks
- **Data Persistence**: Managing volumes for database and web content

### Goal

Create a small infrastructure composed of different services under specific rules:
- Each service runs in a dedicated container
- Services communicate through a custom Docker network
- Data persists through Docker volumes
- Only HTTPS (port 443) is exposed to the outside world

### Architecture

```
Internet → NGINX:443 (TLS) → WordPress:9000 (PHP-FPM) → MariaDB:3306
              ↓                      ↓                        ↓
         SSL/TLS Layer      Content Management         Database
```

All services run on `inception_network` (Docker bridge network) with automatic DNS resolution between containers.

---

## Instructions

### Prerequisites

- Debian-based Linux system (tested on Debian 12)
- Docker Engine 20.10+
- Docker Compose v2+
- Make
- Sudo/root privileges for initial setup

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd Inception
   ```

2. **Set up secrets** (these files are not in the repository):
   ```bash
   mkdir -p secrets
   echo "your_secure_db_password" > secrets/db_password.txt
   echo "your_secure_root_password" > secrets/db_root_password.txt
   echo "your_secure_admin_password" > secrets/wp_admin_password.txt
   chmod 600 secrets/*.txt
   ```

3. **Configure environment**:
   Edit `srcs/.env` if needed (default values should work):
   ```env
   DOMAIN_NAME=asaulnie.42.fr
   MYSQL_DATABASE=wordpress
   MYSQL_USER=wpuser
   HOST_DATA_DIR=/home/asaulnie/data
   ```

4. **Add domain to /etc/hosts**:
   ```bash
   echo "127.0.0.1 asaulnie.42.fr" | sudo tee -a /etc/hosts
   ```

5. **Build and launch**:
   ```bash
   make all
   ```

### Usage

```bash
# Start services
make up

# Stop services
make stop

# View logs
docker logs -f nginx
docker logs -f wordpress
docker logs -f mariadb

# Clean everything (including data)
make down
```

### Access

- **Website**: https://asaulnie.42.fr
- **Admin Panel**: https://asaulnie.42.fr/wp-admin

**Note**: Your browser will warn about the self-signed certificate. This is expected behavior.

---

## Project Description

### Docker and Containerization

This project uses **Docker** to containerize three separate services:

1. **NGINX** - Web server with TLS/SSL termination
2. **WordPress + PHP-FPM** - Content management system
3. **MariaDB** - Database server

Each service is built from a custom Dockerfile based on `debian:stable-slim`, ensuring full control over the installation and configuration process.

### Design Choices

#### Why Custom Dockerfiles?

- **Security**: No unknown code from public images
- **Optimization**: Only install what's needed
- **Learning**: Understand exactly how each service works
- **Compliance**: Meet 42 School requirements

#### Service Communication

Services communicate through a custom Docker bridge network (`inception_network`):
- **DNS Resolution**: Containers can reach each other by name (e.g., `wordpress` resolves to WordPress container IP)
- **Isolation**: Services are isolated from the host network
- **Security**: Only port 443 is exposed externally

#### Data Persistence

Two volumes ensure data survives container restarts:
- `/home/asaulnie/data/mysql` - MariaDB database files
- `/home/asaulnie/data/wordpress` - WordPress installation and uploads

---

## Technical Comparisons

### Virtual Machines vs Docker

| Aspect | Virtual Machines | Docker Containers |
|--------|-----------------|-------------------|
| **Isolation** | Complete OS isolation via hypervisor | Process-level isolation using kernel namespaces |
| **Size** | GBs (full OS per VM) | MBs (shared kernel, minimal overhead) |
| **Startup** | Minutes | Seconds |
| **Resource Usage** | High (dedicated resources) | Low (shared kernel, only app processes) |
| **Portability** | Large .ova/.vmdk files | Small, layered images |
| **Use Case** | Strong isolation, different OSes | Microservices, rapid deployment |

**This Project**: Runs inside a VM for the 42 environment, but uses Docker containers for individual services.

### Secrets vs Environment Variables

| Feature | Docker Secrets | Environment Variables |
|---------|---------------|----------------------|
| **Visibility** | Not shown in `docker inspect` | Visible in `docker inspect` |
| **Storage** | Read-only files in `/run/secrets/` | Process environment |
| **Security** | More secure, can be encrypted | Plain text in memory |
| **Use Case** | Passwords, API keys, certificates | Non-sensitive configuration |

**This Project**: Uses secrets for all passwords (db_password, db_root_password, wp_admin_password) and environment variables for public configuration (domain name, database name).

### Docker Network vs Host Network

| Feature | Bridge Network (Used) | Host Network |
|---------|----------------------|--------------|
| **Isolation** | Yes - separate network namespace | No - shares host network |
| **DNS** | Built-in container name resolution | No automatic DNS |
| **Port Management** | Flexible port mapping | Direct host port usage |
| **Security** | Better isolation | More attack surface |
| **Performance** | Slight overhead from NAT | Native network performance |

**This Project**: Uses a custom bridge network for isolation and automatic service discovery.

### Docker Volumes vs Bind Mounts

| Feature | Volumes (Used) | Bind Mounts |
|---------|---------------|-------------|
| **Management** | Docker-managed | User-managed |
| **Location** | Specified host path | Any host path |
| **Portability** | Controlled location | Absolute paths |
| **Permissions** | Automatically handled | Manual configuration |
| **Backup** | Known, consistent location | Can be anywhere |

**This Project**: Uses volumes with explicit host paths (`/home/asaulnie/data/`) for easy backup and control.

---

## Resources

### Official Documentation

- [Docker Documentation](https://docs.docker.com/) - Container fundamentals, Dockerfile reference
- [Docker Compose Documentation](https://docs.docker.com/compose/) - Multi-container orchestration
- [NGINX Documentation](https://nginx.org/en/docs/) - Web server configuration
- [WordPress Codex](https://codex.wordpress.org/) - WordPress installation and configuration
- [MariaDB Documentation](https://mariadb.org/documentation/) - Database setup and management

### Tutorials and Guides

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/) - Official best practices
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/) - Writing efficient Dockerfiles
- [Docker Security](https://docs.docker.com/engine/security/) - Securing containers
- [NGINX SSL Configuration](https://nginx.org/en/docs/http/configuring_https_servers.html) - TLS/SSL setup
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.php) - FastCGI Process Manager

### Articles

- [Understanding PID 1 in Docker](https://cloud.google.com/architecture/best-practices-for-building-containers#signal-handling) - Process management in containers
- [Docker Networking Explained](https://docs.docker.com/network/) - Network drivers and configurations
- [Docker Volumes Deep Dive](https://docs.docker.com/storage/volumes/) - Data persistence strategies

### AI Usage

AI tools (GitHub Copilot, ChatGPT) were used to assist with:

**Tasks where AI was helpful**:
- **Dockerfile optimization**: Suggestions for reducing image size and improving build times
- **Bash scripting**: Help with entrypoint scripts for service initialization
- **Configuration syntax**: Quick reference for NGINX, PHP-FPM, and MariaDB configuration files
- **Documentation**: Structure and formatting of README, USER_DOC, and DEV_DOC files
- **Troubleshooting**: Debugging Docker networking and permission issues

**Parts written with AI assistance**:
- Initial Dockerfile templates (heavily modified and tested)
- Entrypoint scripts structure (reviewed and adapted for project needs)
- Documentation formatting and organization

**Critical Note**: All AI-generated content was thoroughly reviewed, tested, and modified. Every configuration, script, and command was understood and verified before inclusion. Peer review with other 42 students helped catch issues and validate the approach.

---

## Files and Structure

```
Inception/
├── Makefile                    # Build automation
├── README.md                   # This file
├── USER_DOC.md                 # User documentation
├── DEV_DOC.md                  # Developer documentation
├── .gitignore                  # Exclude secrets from git
├── secrets/                    # Credentials (not in git!)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── docker-compose.yml      # Service orchestration
    ├── .env                    # Environment variables
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/default.conf
        │   ├── ssl/            # Generated certificates
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

---

## Additional Documentation

- **[USER_DOC.md](USER_DOC.md)** - How to use and manage the infrastructure
- **[DEV_DOC.md](DEV_DOC.md)** - Technical details for developers

---

## License

This project is part of the 42 School curriculum and is for educational purposes.

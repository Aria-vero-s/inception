# User Documentation

## Overview

This Inception project provides a complete WordPress website infrastructure running in Docker containers. The stack includes:

- **NGINX**: Web server with TLS/SSL encryption (HTTPS only)
- **WordPress**: Content management system with PHP-FPM
- **MariaDB**: Database server for WordPress data

All services run in isolated Docker containers and communicate through a private network.

---

## Prerequisites

- Debian-based Linux system
- Docker and Docker Compose installed
- Sudo/root access for initial setup
- At least 2GB of free disk space

---

## Starting the Project

1. Navigate to the project directory:
   ```bash
   cd /home/asaulnie/Inception
   ```

2. Build and start all services:
   ```bash
   make all
   ```
   Or separately:
   ```bash
   make build  # Build Docker images
   make up     # Start containers
   ```

3. Wait 10-20 seconds for all services to initialize.

---

## Stopping the Project

- **Stop containers** (keeps data):
  ```bash
  make stop
  ```

- **Stop and remove containers** (keeps data volumes):
  ```bash
  make down
  ```

- **Complete cleanup** (removes containers and volumes):
  ```bash
  make clean
  ```

---

## Accessing the Website

### Main Website
- **URL**: https://asaulnie.42.fr
- **Note**: Your browser will show a security warning because we use a self-signed certificate. This is normal - click "Advanced" and proceed.

### WordPress Admin Panel
- **URL**: https://asaulnie.42.fr/wp-admin
- **First Visit**: You'll need to complete the WordPress installation wizard
- **Admin Credentials**: Located in `/home/asaulnie/Inception/secrets/wp_admin_password.txt`

---

## Managing Credentials

All sensitive credentials are stored in the `secrets/` directory:

| File | Description |
|------|-------------|
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/db_password.txt` | WordPress database user password |
| `secrets/wp_admin_password.txt` | WordPress admin password |

**Security Note**: These files should NEVER be committed to git or shared publicly.

---

## Checking Service Status

1. **Check running containers**:
   ```bash
   docker ps
   ```
   You should see 3 containers: `nginx`, `wordpress`, `mariadb`

2. **View container logs**:
   ```bash
   docker logs nginx
   docker logs wordpress
   docker logs mariadb
   ```

3. **Check service health**:
   ```bash
   # Test NGINX
   curl -k -I https://asaulnie.42.fr
   
   # Check if database is responding
   docker exec mariadb mysqladmin ping
   ```

---

## Data Persistence

All data is stored in `/home/asaulnie/data/`:
- `mysql/` - Database files
- `wordpress/` - Website files and uploads

This data persists even when containers are stopped or removed.

---

## Troubleshooting

### Containers won't start
```bash
# Check logs
docker logs <container_name>

# Restart services
make restart
```

### Website not accessible
```bash
# Verify /etc/hosts has the domain entry
grep asaulnie.42.fr /etc/hosts

# Should show: 127.0.0.1 asaulnie.42.fr
```

### Port 443 already in use
```bash
# Check what's using port 443
sudo lsof -i :443

# Stop the conflicting service or change the port mapping
```

---

## Common Operations

### Restart a specific service
```bash
docker restart nginx
docker restart wordpress
docker restart mariadb
```

### Access container shell
```bash
docker exec -it nginx /bin/bash
docker exec -it wordpress /bin/bash
docker exec -it mariadb /bin/bash
```

### Backup data
```bash
# Backup database
docker exec mariadb mysqldump -u root -p$(cat secrets/db_root_password.txt) wordpress > backup.sql

# Backup WordPress files
tar -czf wordpress-backup.tar.gz /home/asaulnie/data/wordpress/
```

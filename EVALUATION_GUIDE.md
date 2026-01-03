# Inception Project - Evaluation Guide

## Pre-Evaluation Checklist

### Before the evaluator arrives:
1. Make sure containers are DOWN: `cd ~/Inception && make down`
2. Have this guide ready
3. Be prepared to explain concepts clearly

---

## PART 1: Preliminary Tests

### 1.1 Credentials Check
**Evaluator will check**: No credentials in git repository (only in .env)

**What to show**:
```bash
cd ~/Inception
cat .gitignore
```

**What to say**: 
- "All credentials are in the `secrets/` directory and `.env` file"
- "The `.gitignore` file excludes both from git"
- "You can see secrets/ is listed in .gitignore"

---

## PART 2: General Instructions

### 2.1 Project Structure
**Evaluator checks**: `srcs` folder at root, Makefile at root

**What to show**:
```bash
cd ~/Inception
ls -la
tree -L 2 srcs/
```

**What to say**:
- "Makefile is at the root"
- "`srcs/` folder contains all configuration: docker-compose.yml, requirements/, .env"

### 2.2 Clean Environment
**Evaluator runs**:
```bash
docker stop $(docker ps -qa); docker rm $(docker ps -qa); docker rmi -f $(docker images -qa); docker volume rm $(docker volume ls -q); docker network rm $(docker network ls -q) 2>/dev/null
```

**What to say**: "This cleans all Docker resources to ensure a fresh start"

### 2.3 Docker Compose Configuration Check
**Evaluator checks**: docker-compose.yml file

**What to show**:
```bash
cd ~/Inception/srcs
cat docker-compose.yml
```

**What to say**:
- "No `network: host` - we use a custom bridge network called `inception_network`"
- "No `links:` - we use the custom network for container communication"
- "Network is defined at the bottom of the file under `networks:`"

### 2.4 Dockerfile Check
**Evaluator checks**: No prohibited commands in Dockerfiles or entrypoints

**What to show**:
```bash
# Show all Dockerfiles
cat srcs/requirements/nginx/Dockerfile
cat srcs/requirements/wordpress/Dockerfile
cat srcs/requirements/mariadb/Dockerfile

# Show entrypoint scripts
cat srcs/requirements/wordpress/tools/wp-entrypoint.sh
cat srcs/requirements/mariadb/tools/init-db.sh
```

**What to say**:
- "All Dockerfiles use `debian:bookworm-slim` (penultimate stable)"
- "No `tail -f`, `sleep infinity`, or infinite loops"
- "No background processes with `&` in ENTRYPOINT"
- "Services run in foreground: `exec php-fpm8.4 -F`, `exec mysqld`, `exec nginx`"

### 2.5 Build the Project
**Evaluator runs**:
```bash
cd ~/Inception
make
```

**What to say**:
- "The Makefile builds all images and starts containers using docker-compose"
- "It creates volumes at `/home/asaulnie/data/mysql` and `/home/asaulnie/data/wordpress`"

---

## PART 3: Mandatory Part

### 3.1 Project Overview - Explain Concepts

**Evaluator asks**: Explain Docker and docker-compose

**What to say**:

**Docker**:
- "Docker is a containerization platform that packages applications with their dependencies"
- "Containers are isolated, lightweight, and portable"
- "Each container runs a single service (nginx, mariadb, wordpress)"

**Docker Compose**:
- "Docker Compose orchestrates multiple containers as a single application"
- "It uses a YAML file to define services, networks, and volumes"
- "Without compose, you'd need to manually run `docker build` and `docker run` for each service with all the configuration flags"
- "With compose, one `docker-compose up` command builds and starts everything"

**Docker vs VMs**:
- "VMs virtualize hardware - each VM has its own OS kernel"
- "Containers share the host OS kernel - much lighter and faster"
- "VMs take minutes to boot, containers take seconds"
- "Containers use fewer resources (no full OS per container)"

**Directory Structure**:
- "`srcs/` contains all application configuration"
- "`requirements/` has one folder per service, each with its own Dockerfile, config, and tools"
- "Separation makes it modular and maintainable"
- "Each service is independent but communicates via the Docker network"

### 3.2 Simple Setup - Access WordPress

**What to show**:
```bash
# Verify containers are running
sudo docker-compose ps

# Check NGINX is only on port 443
sudo docker ps | grep nginx
```

**What to say**:
- "NGINX only exposes port 443 (HTTPS)"
- "Port 80 (HTTP) is not exposed"

**Evaluator accesses**: https://asaulnie.42.fr in browser

**What to say**:
- "SSL/TLS certificate is self-signed with TLSv1.3"
- "Browser shows certificate warning - that's expected for self-signed certs"
- "You'll see the WordPress site, not the installation page"
- "http://asaulnie.42.fr won't work - only HTTPS"

### 3.3 Docker Basics

**Evaluator checks**: Dockerfiles exist and are custom

**What to show**:
```bash
# Show all Dockerfiles
ls -la srcs/requirements/*/Dockerfile

# Show they start from Debian
head -n 5 srcs/requirements/*/Dockerfile
```

**What to say**:
- "Each service has its own Dockerfile"
- "All built from `debian:bookworm-slim` (Debian 12, penultimate stable)"
- "No pre-made images from DockerHub"
- "Everything is built from scratch using apt packages"

**Verify image names**:
```bash
sudo docker images | grep srcs
```

**What to say**:
- "Images are named `srcs-nginx`, `srcs-wordpress`, `srcs-mariadb`"
- "They match the service names in docker-compose.yml"

### 3.4 Docker Network

**What to show**:
```bash
# Show network in docker-compose.yml
grep -A 3 "networks:" srcs/docker-compose.yml

# List networks
sudo docker network ls

# Inspect the network
sudo docker network inspect srcs_inception_network
```

**What to say**:
- "Custom bridge network `inception_network` connects all services"
- "Services communicate using service names as hostnames"
- "WordPress connects to `mariadb:3306`"
- "NGINX proxies to `wordpress:9000`"
- "Network isolation keeps containers secure"

### 3.5 NGINX with SSL/TLS

**What to show**:
```bash
# Show Dockerfile
cat srcs/requirements/nginx/Dockerfile

# Verify container running
sudo docker-compose ps nginx

# Show SSL certificate
sudo docker exec nginx ls -la /etc/nginx/ssl/

# Show certificate details
sudo docker exec nginx openssl x509 -in /etc/nginx/ssl/server.crt -text -noout | grep -E "(Subject:|Issuer:|Not Before|Not After)"
```

**What to say**:
- "NGINX Dockerfile installs nginx and openssl"
- "SSL certificate is self-signed, generated during build"
- "Certificate CN matches domain: asaulnie.42.fr"
- "TLSv1.2 and TLSv1.3 are enabled in nginx config"

**Verify HTTP blocked**:
```bash
curl http://asaulnie.42.fr
# Should fail or refuse connection
```

**What to say**: "HTTP (port 80) is not exposed - only HTTPS works"

### 3.6 WordPress with php-fpm and Volume

**What to show**:
```bash
# Show Dockerfile (no NGINX)
cat srcs/requirements/wordpress/Dockerfile | grep -i nginx
# Should show nothing

# Verify container
sudo docker-compose ps wordpress

# Check volume
sudo docker volume ls
sudo docker volume inspect srcs_wordpress_data

# Verify mount point
sudo ls -la /home/asaulnie/data/wordpress/
```

**What to say**:
- "WordPress Dockerfile has PHP-FPM, WP-CLI, no NGINX"
- "PHP-FPM listens on port 9000"
- "NGINX proxies requests to WordPress container"
- "Volume persists WordPress files at `/home/asaulnie/data/wordpress/`"

**Test WordPress functionality**:
1. Access https://asaulnie.42.fr
2. Log in with **wpuser** (admin account)
3. Add a comment or create a post
4. Verify it appears on the site

**What to say**:
- "Admin username is `wpuser` (no 'admin' in the name)"
- "WordPress is fully configured - no installation page"
- "There's also a second user: `johndoe` (subscriber role)"

### 3.7 MariaDB and Volume

**What to show**:
```bash
# Show Dockerfile (no NGINX)
cat srcs/requirements/mariadb/Dockerfile | grep -i nginx
# Should show nothing

# Verify container
sudo docker-compose ps mariadb

# Check volume
sudo docker volume ls
sudo docker volume inspect srcs_mysql_data

# Verify mount point
sudo ls -la /home/asaulnie/data/mysql/
```

**What to say**:
- "MariaDB Dockerfile only has MariaDB, no NGINX"
- "Volume persists database at `/home/asaulnie/data/mysql/`"

**Login to database**:
```bash
# Show how to access
sudo docker exec -it mariadb mysql -u root -p
# Password: 123_root_password_asd
```

**Inside MySQL, show database**:
```sql
SHOW DATABASES;
USE wordpress_db;
SHOW TABLES;
SELECT user_login, user_email FROM wp_users;
EXIT;
```

**What to say**:
- "Database `wordpress_db` contains WordPress data"
- "Two users: `wpuser` (admin) and `johndoe` (subscriber)"
- "Tables include wp_users, wp_posts, wp_options, etc."

### 3.8 Persistence Test

**Evaluator requests**: Reboot the VM

**What to do**:
```bash
# Stop containers
cd ~/Inception
make down

# Simulate reboot or actually reboot
sudo reboot
# (If you don't want to reboot, just stop/start containers)

# After "reboot", restart
cd ~/Inception
make

# Wait for containers to start
sudo docker-compose ps
```

**What to show**:
```bash
# Verify WordPress changes persist
# Access https://asaulnie.42.fr in browser
# The comment/post you added earlier should still be there

# Verify database persists
sudo docker exec -it mariadb mysql -u root -p123_root_password_asd -e "USE wordpress_db; SELECT COUNT(*) FROM wp_posts;"
```

**What to say**:
- "Volumes persist data even when containers are destroyed"
- "WordPress files and database survive container restarts"
- "Changes made to website are preserved"

---

## PART 4: Bonus (If Applicable)

**Note**: You haven't implemented bonus services in this project.

**What to say**: "I focused on perfecting the mandatory part. No bonus services were implemented."

---

## Common Questions & Answers

### Q: Why did you choose Debian over Alpine?
**A**: "Debian provides better compatibility with PHP-FPM and WordPress. It's more stable for production-like environments."

### Q: How do containers communicate?
**A**: "Through the custom bridge network `inception_network`. Services use service names as DNS: nginx→wordpress:9000, wordpress→mariadb:3306"

### Q: What happens if MariaDB crashes?
**A**: "Docker restart policy `unless-stopped` automatically restarts crashed containers"

### Q: Where are passwords stored?
**A**: "In two places: `secrets/` directory (for Docker secrets) and `srcs/.env` file (for environment variables). Both excluded from git via .gitignore"

### Q: How is WordPress configured automatically?
**A**: "The entrypoint script uses WP-CLI to install WordPress and create users if not already installed. It checks with `wp core is-installed` first."

### Q: Why use volumes instead of bind mounts?
**A**: "Docker volumes are managed by Docker, portable, and work across different host systems. Better for production."

---

## Quick Command Reference

```bash
# Project directory
cd ~/Inception

# Build and start
make

# Stop containers
make down

# View logs
sudo docker-compose logs [service_name]

# Container status
sudo docker-compose ps

# Execute command in container
sudo docker exec -it [container_name] [command]

# Volume inspection
sudo docker volume ls
sudo docker volume inspect [volume_name]

# Network inspection
sudo docker network ls
sudo docker network inspect srcs_inception_network

# Access database
sudo docker exec -it mariadb mysql -u root -p
# Password: 123_root_password_asd

# View WordPress files
sudo ls -la /home/asaulnie/data/wordpress/

# View MariaDB files
sudo ls -la /home/asaulnie/data/mysql/
```

---

## Evaluation Tips

1. **Be confident**: You know your project, explain clearly
2. **Be honest**: If you don't know something, say so, then figure it out together
3. **Show understanding**: Don't just run commands, explain what they do
4. **Be patient**: Evaluator might not know Docker well - help them learn
5. **Have documentation ready**: README.md, USER_DOC.md, DEV_DOC.md

---

## Final Checklist

- [ ] All containers running and healthy
- [ ] Website accessible via HTTPS only
- [ ] Two WordPress users exist (wpuser, johndoe)
- [ ] SSL certificate is self-signed with correct CN
- [ ] Volumes persist data
- [ ] No prohibited commands in Dockerfiles
- [ ] No credentials in git repository
- [ ] Custom bridge network configured
- [ ] Can explain Docker concepts clearly

---

## Expected Grade: 100/100

Good luck with your evaluation! 🚀

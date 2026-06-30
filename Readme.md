# Cloud-1 Ansible Deployment

This Ansible project automates the deployment of a WordPress application stack with MariaDB, Nginx, phpMyAdmin, and Adminer on one or more remote servers using Docker containers.

## 📋 Overview

This playbook sets up a complete infrastructure and deploys a containerized WordPress application with the following components:

- **MariaDB**: Database server for WordPress
- **WordPress**: Content management system running on PHP-FPM
- **Nginx**: Reverse proxy and web server with SSL/TLS support
- **phpMyAdmin**: Web-based database management interface
- **Adminer**: Lightweight database management tool
- **UFW**: Firewall configuration
- **Docker & Docker Compose**: Container orchestration

## 🏗️ Architecture

The application runs in Docker containers orchestrated by Docker Compose, with the following network topology:

```
Internet → Nginx (443/80) → WordPress (9000)
                          → phpMyAdmin (via proxy)
                          → Adminer (via proxy)
                          ↓
                       MariaDB (3306)
```

## 📁 Project Structure

```
ansible/
├── ansible.cfg                 # Ansible configuration
├── hosts.yml                   # Inventory file - one entry per server
├── playbook.yml                # Main playbook
├── group_vars/
│   └── cloud_1_server/
│       └── vars.yml            # Vars shared by every server (deploy user, image tags, ...)
├── host_vars/
│   ├── server1/
│   │   ├── vars.yml            # Per-server config (domain, deploy path, db name/user, ...)
│   │   └── vault.yml           # Per-server secrets (passwords) - plaintext for now, see Vault Secrets below
│   └── server2/                # Template for adding another server
│       ├── vars.yml
│       └── vault.yml
├── host_files/
│   ├── README.md
│   └── <hostname>/ssl/         # That server's SSL cert + key (fullchain.pem, <domain>.key)
└── roles/
    ├── python/                 # Python installation
    ├── docker/                 # Docker installation and setup
    ├── docker_compose/         # Docker Compose plugin installation
    ├── ufw/                    # Firewall configuration
    ├── mariadb/                # MariaDB Dockerfile, setup script, .env
    ├── wordpress/              # WordPress Dockerfile, setup script, .env
    ├── nginx/                  # Nginx Dockerfile, config template, SSL deployment
    ├── phpmyadmin/             # phpMyAdmin image/config (official image, no build context)
    ├── adminer/                # Adminer image/config (official image, no build context)
    ├── deploy_app/             # Orchestrator: renders docker-compose.yml, brings the stack up, waits for it to be healthy
    └── cleanup/                # Cleanup role for removing Docker/containers
```

## 🔧 Prerequisites

- Ansible 2.9+ installed on your control machine
- Target server(s) running Ubuntu/Debian
- SSH access to the target server(s) with sudo privileges
- SSL certificates placed in `host_files/<hostname>/ssl/`
- Ansible Vault password, once vault files are actually encrypted (see below)

## ⚙️ Configuration

### 1. Inventory Setup

Edit [`hosts.yml`](hosts.yml) and add one entry per server under `cloud_1_server`. The server's IP address (or domain name) goes in `ansible_host`:

```yaml
all:
  children:
    cloud_1_server:
      hosts:
        server1:
          ansible_host: is-wis.com
        server2:
          ansible_host: 203.0.113.10
```

Every host in `cloud_1_server` is deployed to in a single `ansible-playbook` run.

### 2. Adding a server (multi-server deployment)

1. Add the host to `hosts.yml` as above.
2. Create `host_vars/<hostname>/vars.yml` and `host_vars/<hostname>/vault.yml` - copy `host_vars/server2/` as a starting template and fill in real values (domain, deploy path, DB/admin credentials).
3. Put that server's SSL cert in `host_files/<hostname>/ssl/` - see [`host_files/README.md`](host_files/README.md).
4. Run the playbook normally; it deploys to every host in the group (in parallel, by default 5 forks). Use `--limit <hostname>` to target just one server.

### 3. Variables Configuration

- **`group_vars/cloud_1_server/vars.yml`**: settings shared by every server (deploy SSH user, Python interpreter, MariaDB container hostname/port, pinned phpMyAdmin/Adminer image tags).
- **`host_vars/<hostname>/vars.yml`**: settings specific to one server (domain, deploy path, DB name/user, WordPress admin username/email, UFW custom ports).
- **`host_vars/<hostname>/vault.yml`**: secrets specific to one server (sudo password, DB password, WordPress admin/user passwords).

### 4. Vault Secrets

`host_vars/<hostname>/vault.yml` currently holds **plaintext** secrets and is excluded from git via `.gitignore`. Encrypt it with Ansible Vault before this goes anywhere near production:

```bash
ansible-vault encrypt host_vars/server1/vault.yml
```

Then remove the corresponding line from `.gitignore` (an encrypted vault file is safe, and meant, to be committed), and pass `--ask-vault-pass` (or `--vault-password-file`) to every `ansible-playbook` run.

## 🚀 Usage

### Full Deployment (all servers)

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

### Single Server

```bash
ansible-playbook playbook.yml --ask-vault-pass --limit server1
```

### Tagged Deployments

Use tags to run specific parts of the playbook:

#### Infrastructure Only
```bash
ansible-playbook playbook.yml --ask-vault-pass --tags infra
```

#### Application Deployment Only
```bash
ansible-playbook playbook.yml --ask-vault-pass --tags app
```

#### Specific Components
```bash
# Install only Python
ansible-playbook playbook.yml --ask-vault-pass --tags python

# Install only Docker
ansible-playbook playbook.yml --ask-vault-pass --tags docker

# Configure firewall only
ansible-playbook playbook.yml --ask-vault-pass --tags ufw

# Deploy a single service (e.g. just refresh WordPress' files/.env)
ansible-playbook playbook.yml --ask-vault-pass --tags wordpress

# Deploy application only (all services + the compose orchestrator)
ansible-playbook playbook.yml --ask-vault-pass --tags deploy
```

#### Cleanup
Remove all Docker containers, images, volumes, and packages:
```bash
ansible-playbook playbook.yml --ask-vault-pass --tags cleanup
```

## 🏷️ Available Tags

| Tag | Description |
|-----|-------------|
| `python` | Install Python and pip |
| `docker` | Install Docker CE |
| `docker_compose` | Install Docker Compose plugin |
| `ufw` | Configure UFW firewall |
| `mariadb` | Stage MariaDB Dockerfile/.env |
| `wordpress` | Stage WordPress Dockerfile/.env |
| `nginx` | Stage Nginx Dockerfile/config/SSL |
| `phpmyadmin` | phpMyAdmin config (image tag) |
| `adminer` | Adminer config (image tag) |
| `deploy` | Render docker-compose.yml, build/start the stack, wait for readiness |
| `infra` | Run all infrastructure roles (python, docker, docker_compose, ufw) |
| `app` | Run all application-related roles (infra + every service + deploy) |
| `cleanup` | Remove all Docker resources and packages |

## 🔒 Security Features

- **SSL/TLS**: Nginx configured with TLS 1.2/1.3
- **HSTS**: Strict-Transport-Security headers enabled
- **UFW Firewall**: Configured to allow only necessary ports:
  - 22 (SSH)
  - 80 (HTTP - redirects to HTTPS)
  - 443 (HTTPS)
  - Anything added per-host via `ufw_custom_ports` (empty by default - phpMyAdmin/Adminer are only reachable through the Nginx reverse proxy on 443, their container ports are never published to the host)
- **Ansible Vault**: secrets isolated in `host_vars/<hostname>/vault.yml`, ready to be encrypted (see Vault Secrets above)
- **Docker**: Containers isolated on a bridge network

## 📦 Roles Description

### python
Installs Python 3, pip, and virtual environment support.

### docker
Installs Docker CE, configures repository, starts service, and adds user to docker group.

### docker_compose
Installs Docker Compose plugin (V2).

### ufw
Configures UFW firewall with default deny incoming policy and allows specified ports.

### mariadb / wordpress / nginx
Each stages its own Docker build context (Dockerfile, setup script) and its own `.env`/config under `{{ app_deploy_path }}/<service>/`. The `nginx` role additionally renders `nginx.conf` from `domain_name` and copies that host's SSL cert/key from `host_files/<hostname>/ssl/`.

### phpmyadmin / adminer
Run from official images (no custom build context) - these roles just own that service's pinned image tag (`defaults/main.yml`), consumed by `deploy_app`'s compose template.

### deploy_app
- Creates the application directory
- Renders `docker-compose.yml` referencing every service above
- Builds and starts the stack (`docker compose up -d --build`)
- Waits for MariaDB, WordPress, and Nginx to be ready
- Displays container status

### cleanup
Complete cleanup role that:
- Stops Docker and containerd services
- Removes all containers, volumes, and images
- Purges Docker and related packages
- Removes configuration files

## 🌐 Access Points

After deployment, the following services are available (per server, using that server's `domain_name`):

- **WordPress**: `https://your-domain.com`
- **phpMyAdmin**: `https://phpmyadmin.your-domain.com`
- **Adminer**: `https://adminer.your-domain.com`

## 🔍 Troubleshooting

### Check container status
```bash
cd /path/to/app/deployment
docker compose ps
docker compose logs
```

### View Ansible logs
```bash
ansible-playbook playbook.yml --ask-vault-pass -v   # Verbose
ansible-playbook playbook.yml --ask-vault-pass -vvv # Very verbose
```

### Verify firewall rules
```bash
sudo ufw status verbose
```

### Test connectivity
```bash
# Test database connection
docker exec mariadb mariadb -u username -p -e "SELECT 1"

# Check WordPress installation
docker exec wordpress ls -la /var/www/wordpress/
```

## 📝 Notes

- The playbook uses `become: true` for privilege escalation
- All sensitive data should be stored in `host_vars/<hostname>/vault.yml`, encrypted with Ansible Vault
- SSL certificates must be provided per-host in `host_files/<hostname>/ssl/`
- The deployment waits for services to be ready with configurable retries
- Containers are automatically restarted on failure

## 🤝 Contributing

When modifying this playbook:
1. Test changes in a development environment first
2. Update vault variables as needed
3. Follow Ansible best practices for role structure
4. Document any new variables or configuration options

**Last Updated**: June 30, 2026

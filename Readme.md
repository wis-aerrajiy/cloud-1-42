# Cloud-1 Ansible Deployment

This Ansible project automates the deployment of a WordPress application stack with MariaDB, Nginx, phpMyAdmin, and Adminer on a remote server using Docker containers.

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
├── hosts.yml                   # Inventory file
├── playbook.yml               # Main playbook
├── group_vars/
│   └── cloud_1_server/
│       ├── vars.yml           # Group variables
│       └── cloud_1_server_vault.yml  # Encrypted secrets
└── roles/
    ├── python/                # Python installation
    ├── docker/                # Docker installation and setup
    ├── docker_compose/        # Docker Compose plugin installation
    ├── ufw/                   # Firewall configuration
    ├── deploy_app/            # Application deployment
    │   ├── files/
    │   │   ├── mariadb/       # MariaDB Dockerfile and scripts
    │   │   ├── wordpress/     # WordPress Dockerfile and scripts
    │   │   └── nginx/         # Nginx Dockerfile, config, and SSL certs
    │   ├── tasks/
    │   │   └── main.yml       # Deployment tasks
    │   └── templates/
    │       ├── .env.j2        # Environment variables template
    │       └── docker-compose.yml.j2  # Docker Compose template
    └── cleanup/               # Cleanup role for removing Docker/containers
```

## 🔧 Prerequisites

- Ansible 2.9+ installed on your control machine
- Target server running Ubuntu/Debian
- SSH access to the target server with sudo privileges
- SSL certificates placed in the appropriate directory
- Ansible Vault password for encrypted variables

## ⚙️ Configuration

### 1. Inventory Setup

Edit [`hosts.yml`](hosts.yml) to configure your target server:

```yaml
all:
  children:
    cloud_1_server:
      hosts:
        is-wis.com:
```

### 2. Variables Configuration

Configure variables in [`group_vars/cloud_1_server/vars.yml`](group_vars/cloud_1_server/vars.yml):

- Connection settings (host, user, SSH key)
- Database configuration (name, user, password)
- WordPress settings (domain, admin credentials)
- Custom firewall ports

### 3. Vault Secrets

Create and encrypt sensitive data using Ansible Vault:

```bash
ansible-vault create group_vars/cloud_1_server/cloud_1_server_vault.yml
```

Required vault variables:
- `vault_server_ip`: Server IP address
- `vault_ssh_private_key_file`: Path to SSH private key
- `vault_become_pass`: Sudo password
- `vault_app_deploy_path`: Application deployment directory
- `vault_domain_name`: Your domain name
- `vault_db_name`, `vault_db_user`, `vault_db_pass`: Database credentials
- `vault_site_title`: WordPress site title
- `vault_admin_user`, `vault_admin_pass`, `vault_admin_mail`: WordPress admin credentials
- `vault_user_user`, `vault_user_mail`, `vault_user_pass`: WordPress user credentials

## 🚀 Usage

### Full Deployment

Deploy the complete infrastructure and application:

```bash
ansible-playbook playbook.yml --ask-vault-pass
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

# Deploy application only
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
| `deploy` | Deploy application containers |
| `infra` | Run all infrastructure roles (python, docker, docker_compose, ufw) |
| `app` | Run all application-related roles (infra + deploy) |
| `cleanup` | Remove all Docker resources and packages |

## 🔒 Security Features

- **SSL/TLS**: Nginx configured with TLS 1.2/1.3
- **HSTS**: Strict-Transport-Security headers enabled
- **UFW Firewall**: Configured to allow only necessary ports:
  - 22 (SSH)
  - 80 (HTTP - redirects to HTTPS)
  - 443 (HTTPS)
  - 8080 (Adminer)
  - 8081 (phpMyAdmin)
- **Ansible Vault**: Sensitive data encrypted
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

### deploy_app
- Creates application directory structure
- Deploys Docker Compose configuration
- Copies Dockerfiles and scripts for MariaDB, WordPress, and Nginx
- Builds and starts containers
- Waits for services to be ready
- Displays container status

### cleanup
Complete cleanup role that:
- Stops Docker and containerd services
- Removes all containers, volumes, and images
- Purges Docker and related packages
- Removes configuration files

## 🌐 Access Points

After deployment, the following services are available:

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
- All sensitive data should be stored in the vault file
- SSL certificates must be provided in the nginx/ssl directory
- The deployment waits for services to be ready with configurable retries
- Containers are automatically restarted on failure

## 🤝 Contributing

When modifying this playbook:
1. Test changes in a development environment first
2. Update vault variables as needed
3. Follow Ansible best practices for role structure
4. Document any new variables or configuration options

**Last Updated**: January 8, 2026
Here's a comprehensive README.md that documents all the enhancements:

```markdown
# 🛠️ Ansible Basic Server Configuration

A production-ready Ansible playbook for automated Ubuntu/Debian/RHEL server provisioning with comprehensive security hardening, monitoring, and configuration management.

## 📋 Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage Examples](#usage-examples)
- [Roles Documentation](#roles-documentation)
- [Security Features](#security-features)
- [Monitoring & Reporting](#monitoring--reporting)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## ✨ Features

### Core Functionality
- 🔐 **Automated Security Hardening** - UFW firewall, Fail2ban, SSH hardening
- 👥 **User Management** - Multi-user support with SSH keys and sudo configuration
- 📦 **Package Management** - Automatic security updates and custom package installation
- 🔄 **Multi-Distribution Support** - Ubuntu, Debian, and RHEL/CentOS compatible
- 📊 **Comprehensive Reporting** - HTML reports, logging, and execution summaries
- 🎯 **Environment Support** - Development, staging, and production configurations

### Advanced Features
- **Dynamic Inventory** - Support for cloud providers (AWS, DigitalOcean)
- **Idempotent Operations** - Safe to run multiple times
- **Check Mode** - Preview changes before applying
- **Performance Optimized** - SSH pipelining, fact caching, parallel execution
- **Flexible Configuration** - Tag-based selective execution

## 📦 Requirements

### Control Machine
- Python 3.8+
- Ansible 2.12+
- SSH client
- Unix-like OS (Linux, macOS, WSL)

### Target Servers
- Ubuntu 20.04+ / Debian 10+ / RHEL 8+ / CentOS 8+
- Python 3 installed
- SSH access with sudo privileges
- Minimum 1GB RAM, 10GB disk space

### Python Dependencies
```bash
pip install ansible ansible-lint jinja2
```

## 🚀 Quick Start

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/ansible-basic-server-configuration.git
cd ansible-basic-server-configuration
```

2. **Set up environment**
```bash
cp .env.example .env
# Edit .env with your credentials
vim .env
```

3. **Configure inventory**
```bash
# Edit inventory.ini with your server details
vim inventory.ini
```

4. **Run the playbook**
```bash
./run.sh
```

## 📁 Project Structure

```
.
├── ansible.cfg              # Ansible configuration
├── inventory.ini            # Server inventory (or inventory.yml)
├── playbook.yml            # Main playbook
├── run.sh                  # Execution script with reporting
├── .env.example            # Environment variables template
├── group_vars/             # Group variables
│   └── all.yml            # Global variables
├── config/                 # Configuration files
│   ├── apt/               # APT configurations
│   │   ├── 10periodic
│   │   ├── 20auto-upgrades
│   │   ├── 50unattended-upgrades
│   │   └── 99local
│   ├── fail2ban/          # Fail2ban configs
│   │   ├── jail.local
│   │   ├── jail.d/
│   │   ├── filter.d/
│   │   └── action.d/
│   └── ssh/               # SSH configurations
│       ├── 99-custom.conf
│       ├── banner.txt
│       └── sshd_config.d/
├── logs/                   # Execution logs (auto-created)
├── reports/                # HTML reports (auto-created)
└── roles/                  # Ansible roles
    ├── system_update/
    ├── user_management/
    ├── ssh_hardening/
    ├── firewall/
    ├── fail2ban/
    ├── common_packages/
    ├── automatic_updates/
    └── timezone/
```

## 🔧 Installation

### 1. Install Ansible

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install python3-pip python3-venv git
pip3 install --user ansible ansible-lint
```

**RHEL/CentOS:**
```bash
sudo yum install python3 python3-pip git
pip3 install --user ansible ansible-lint
```

**macOS:**
```bash
brew install ansible
```

### 2. Clone Repository
```bash
git clone https://github.com/yourusername/ansible-basic-server-configuration.git
cd ansible-basic-server-configuration
```

### 3. Configure Environment

Create `.env` file:
```bash
# Copy template
cp .env.example .env

# Edit with your values
cat > .env << 'EOF'
# Default SSH credentials
ANSIBLE_USER=ubuntu
ANSIBLE_PASSWORD=your_secure_password

# SSH key authentication (recommended)
ANSIBLE_SSH_KEY=~/.ssh/id_rsa

# Custom SSH port (if different from 22)
ANSIBLE_SSH_PORT=22

# Email for notifications
ADMIN_EMAIL=admin@example.com
EOF
```

### 4. Set Up Inventory

**Option 1: INI format (inventory.ini)**
```ini
[servers]
web-server ansible_host=192.168.1.100
db-server ansible_host=192.168.1.101

[servers:vars]
ansible_user={{ lookup('env', 'ANSIBLE_USER') }}
ansible_password={{ lookup('env', 'ANSIBLE_PASSWORD') }}
```

**Option 2: YAML format (inventory.yml)**
```yaml
all:
  children:
    servers:
      hosts:
        web-server:
          ansible_host: 192.168.1.100
        db-server:
          ansible_host: 192.168.1.101
      vars:
        ansible_user: "{{ lookup('env', 'ANSIBLE_USER') }}"
```

## 🎯 Usage Examples

### Basic Usage

**Run complete configuration:**
```bash
./run.sh
```

**Check mode (dry run):**
```bash
./run.sh --check
```

**Verbose output:**
```bash
./run.sh -v    # Verbose
./run.sh -vv   # More verbose
./run.sh -vvv  # Debug level
```

### Selective Execution

**Run only security-related tasks:**
```bash
./run.sh --tags security
```

**Skip firewall configuration:**
```bash
./run.sh --skip-tags firewall
```

**Configure specific servers:**
```bash
./run.sh --limit web-server
./run.sh --limit "web*"  # Wildcard pattern
```

### Environment-Specific Runs

**Development environment:**
```bash
./run.sh --env dev
```

**Staging with specific tags:**
```bash
./run.sh --env staging --tags "packages,updates"
```

### Advanced Examples

**Configure only user management:**
```bash
./run.sh --tags users --limit production
```

**Update packages without rebooting:**
```bash
./run.sh --tags packages --skip-tags reboot
```

**Security audit mode:**
```bash
./run.sh --tags security --check -v
```

**Emergency security patching:**
```bash
./run.sh --tags "updates,security" --limit "*" -e "force_reboot=true"
```

### Using Ansible Directly

**List all hosts:**
```bash
ansible-inventory -i inventory.ini --list
```

**Ping all servers:**
```bash
ansible -i inventory.ini all -m ping
```

**Run ad-hoc commands:**
```bash
ansible -i inventory.ini servers -a "uptime"
ansible -i inventory.ini servers -m shell -a "df -h"
```

## 📚 Roles Documentation

### 1. System Update (`system_update`)
Updates system packages and handles reboots when required.

**Variables:**
- `auto_reboot`: Enable automatic reboot (default: false)
- `reboot_timeout`: Reboot timeout in seconds (default: 600)

**Tags:** `updates`, `packages`

### 2. User Management (`user_management`)
Creates users, configures SSH keys, and sets up sudo access.

**Variables:**
```yaml
# Legacy single user
NEW_USER_NAME: john
NEW_USER_PASSWORD: secure_password
SSH_KEY_PATH: /path/to/public/key

# Modern multi-user approach
users:
  - name: alice
    groups: [sudo, docker]
    ssh_keys: ["ssh-rsa AAAA..."]
    sudo: true
  - name: bob
    state: absent  # Remove user
```

**Tags:** `users`, `ssh`, `sudo`

### 3. SSH Hardening (`ssh_hardening`)
Implements SSH security best practices.

**Features:**
- Disables password authentication
- Configures key-based authentication only
- Implements crypto hardening (Mozilla Modern)
- Sets up login banners
- Configures idle timeouts

**Tags:** `ssh`, `security`

### 4. Firewall (`firewall`)
Configures UFW with common service rules.

**Variables:**
```yaml
firewall_allowed_ports:
  - { port: 22, proto: tcp, comment: "SSH" }
  - { port: 80, proto: tcp, comment: "HTTP" }
  - { port: 443, proto: tcp, comment: "HTTPS" }
firewall_allowed_networks:
  - { network: "10.0.0.0/8", comment: "Internal" }
```

**Tags:** `firewall`, `security`, `ufw`

### 5. Fail2ban (`fail2ban`)
Intrusion prevention system configuration.

**Jails configured:**
- SSH (standard and aggressive)
- Port scanning detection
- Recidive (repeat offenders)
- Web server protection (nginx/Apache)
- Authentication failures

**Tags:** `fail2ban`, `security`, `ids`

### 6. Common Packages (`common_packages`)
Installs essential packages.

**Default packages:**
- System: htop, iotop, ncdu, tree
- Network: curl, wget, net-tools, traceroute
- Development: git, vim, tmux
- Security: aide, rkhunter
- Monitoring: sysstat, iftop

**Tags:** `packages`, `tools`

### 7. Automatic Updates (`automatic_updates`)
Configures unattended security updates.

**Features:**
- Daily security updates
- Automatic dependency management
- Old kernel cleanup
- Optional automatic reboot
- Email notifications

**Tags:** `updates`, `security`, `cron`

### 8. Timezone (`timezone`)
Sets system timezone and configures NTP.

**Variables:**
```yaml
system_timezone: "America/New_York"
ntp_servers:
  - 0.pool.ntp.org
  - 1.pool.ntp.org
```

**Tags:** `timezone`, `ntp`, `time`

## 🔐 Security Features

### Implemented Security Measures

1. **SSH Security**
   - Public key authentication only
   - Root login disabled
   - Strong ciphers (Mozilla Modern)
   - Connection rate limiting
   - Idle session timeouts

2. **Firewall Protection**
   - Default deny incoming
   - Minimal open ports
   - Connection tracking
   - Rate limiting
   - Geographic restrictions (optional)

3. **Intrusion Prevention**
   - Fail2ban with multiple jails
   - Automatic IP banning
   - Port scan detection
   - Recidive jail for repeat offenders

4. **System Hardening**
   - Automatic security updates
   - Kernel parameters tuning
   - Service minimization
   - File permission hardening
   - Process accounting

5. **Access Control**
   - Sudo configuration
   - User access restrictions
   - Password policies
   - SSH key management

### Security Compliance

This playbook helps meet requirements for:
- CIS Ubuntu/Debian/RHEL Benchmarks
- PCI DSS (partial)
- NIST 800-53 (basic controls)
- SOC 2 Type II (partial)

## 📊 Monitoring & Reporting

### Execution Reports

Each run generates:
1. **Text log** - Complete execution output
2. **HTML report** - Visual summary with statistics
3. **JSON output** - Machine-readable results
4. **Summary file** - Quick overview

### Report Features
- Execution status and duration
- Task statistics (OK, Changed, Failed)
- Target host information
- Complete execution log
- Responsive HTML design
- Print-friendly format

### Accessing Reports
```bash
# View latest report
ls -la reports/

# Open in browser
xdg-open reports/ansible_report_*.html
```

## 🔧 Troubleshooting

### Common Issues

**1. SSH Connection Failed**
```bash
# Test SSH connection
ssh -v user@host

# Check SSH key
ssh-add -l

# Verify inventory
ansible -i inventory.ini all -m ping
```

**2. Sudo Password Issues**
```bash
# Test with manual password
ansible-playbook playbook.yml --ask-become-pass

# Check sudo configuration
ssh user@host sudo -l
```

**3. Package Installation Failures**
```bash
# Update package cache
./run.sh --tags packages -e "update_cache=true"

# Check specific package
ansible -i inventory.ini all -m package -a "name=vim state=present"
```

**4. Firewall Blocking Ansible**
```bash
# Temporarily disable firewall
ansible -i inventory.ini all -m command -a "ufw disable" --become

# Re-run playbook
./run.sh

# Firewall is automatically re-enabled by playbook
```

### Debug Mode
```bash
# Maximum verbosity
./run.sh -vvv

# Enable Ansible debug
export ANSIBLE_DEBUG=1
./run.sh

# Check specific task
./run.sh --tags security --start-at-task="Configure firewall rules"
```

### Log Analysis
```bash
# Search for errors
grep -i error logs/ansible_run_*.log

# Find changed tasks
grep -E "changed:|CHANGED" logs/ansible_run_*.log

# Check specific host
grep -A5 -B5 "192.168.1.100" logs/ansible_run_*.log
```

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Guidelines
- Follow Ansible best practices
- Test on multiple distributions
- Update documentation
- Add appropriate tags
- Ensure idempotency

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Ansible Documentation](https://docs.ansible.com/)
- [Mozilla SSH Guidelines](https://infosec.mozilla.org/guidelines/openssh)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)
- [ansible-hardening](https://github.com/dev-sec/ansible-collection-hardening)
- [mist941](https://github.com/mist941)

## 📞 Support

---
Made with ❤️ by [cirrus365](https://github.com/cirrus365)
```

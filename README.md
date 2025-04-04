# Basic Server Configuration

An Ansible playbook for automating secure server setup and configuration with sensible defaults for systems.

## 🚀 Features

- **System Updates**: Keeps your servers up-to-date with the latest security patches
- **Logging & Reporting**: 
  - Configures system logging with rsyslog
  - Sets up log rotation with logrotate
  - Generates HTML execution reports
  - Maintains detailed Ansible logs
- **User Management**: Creates a secure non-root user with sudo privileges
- **SSH Hardening**: Configures SSH for key-based authentication only
- **Firewall Setup**: Installs and configures UFW with secure defaults
- **Security Enhancements**:
  - Fail2ban for intrusion prevention
  - Automatic security updates
  - Sensible security defaults
- **Time Synchronization**: Configures NTP for accurate system time
- **Essential Packages**: Installs common utilities (vim, curl, htop, git, mtr)

## 📋 Prerequisites

- Ansible 2.9+
- SSH key pair
- Target Ubuntu servers
- Local environment variables

## 🔧 Setup & Configuration

1. Clone this repository:
   ```
   git clone https://github.com/yourusername/basic-server-configuration.git
   cd basic-server-configuration
   ```

2. Configure environment variables in the `.env` file, you can follow the sample file provided and fill in your data

3. Update the `inventory.ini` file with your server IP addresses:
   ```ini
   [servers]
   192.168.1.10
   192.168.1.11
   # Add your servers here
   ```

4. Run the playbook:
   ```
   ./run.sh
   ```

## 🛡️ What Gets Configured

- Creates a new sudo user with SSH key authentication
- Disables SSH password authentication and root login
- Configures firewall (UFW) to allow only SSH
- Sets up Fail2ban to prevent brute-force attacks
- Configures automatic security updates
- Installs essential system utilities
- Sets timezone to Europe/Kyiv (configurable)
- Configures comprehensive system logging with rsyslog
- Sets up log rotation to manage log file sizes
- Creates a dedicated directory for application logs
- Implements basic log monitoring for large log files
- Generates detailed HTML reports for each playbook run

## ⚙️ Customization

The playbook has been modularized into roles for better organization and maintainability. To customize:

- **System Updates**: Edit `roles/system_updates/tasks/main.yml`
- **Logging Setup**: Edit `roles/logging_setup/tasks/main.yml`
  - Modify rsyslog configuration in `roles/logging_setup/templates/rsyslog.conf.j2`
  - Adjust log rotation settings in `roles/logging_setup/files/logrotate.conf`
- **Time Configuration**: Edit `roles/time_configuration/tasks/main.yml`
- **SSH Setup**: Edit `roles/ssh_setup/tasks/main.yml`
- **User Management**: Edit `roles/user_management/tasks/main.yml`
- **Package Installation**: Edit `roles/package_installation/tasks/main.yml`
- **Security Setup**: Edit `roles/security_setup/tasks/main.yml`
- **Automatic Updates**: Edit `roles/automatic_updates/tasks/main.yml`

Common customizations:
- Change the timezone: Edit the timezone task in `roles/time_configuration/tasks/main.yml`
- Modify the package list: Edit the package list in `roles/package_installation/tasks/main.yml`
- Adjust security settings: Edit the security settings in `roles/security_setup/tasks/main.yml`
- Configure logging:
  - Enable remote logging: Uncomment and configure the remote logging line in `roles/logging_setup/templates/rsyslog.conf.j2`
  - Change log rotation frequency: Modify rotation settings in `roles/logging_setup/files/logrotate.conf`
  - Add custom application logs: Add new log paths in both rsyslog and logrotate configurations
- Add or remove configuration tasks: Add or remove tasks in the appropriate role's task file

## 🤝 Contributions

Stars and contributions are highly appreciated! If you find this project useful, please consider:

- ⭐ Starring the repository
- 🔀 Creating a pull request with enhancements
- 🐛 Opening issues for bugs or feature requests
- 📢 Sharing with fellow sysadmins and DevOps engineers

Let's collaborate to build a more robust, secure, and feature-rich server configuration tool together!

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

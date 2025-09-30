## [unreleased]

### 🚀 Features

- Add comprehensive infrastructure as code implementation
- *(ansible)* Implement MicroK8s cluster automation with enterprise features
- *(tasks)* Add comprehensive task management system template
- Add new Claude workflow commands
- Add Ansible infrastructure automation
- Add task management system
- *(tasks)* Add first practical learning task and directories
- *(ansible)* Add infrastructure automation for MicroK8s
- *(tasks)* Align task system with infrastructure-as-code approach
- *(docs)* Add developer tools guide and changelog tooling
- *(terraform)* Add SSH username configuration to Proxmox provider
- *(terraform)* Add multi-node deployment across Proxmox cluster
- *(terraform)* Enhance VM configuration with advanced Proxmox features
- *(docs)* Enhance terraform-docs integration and cleanup
- *(terraform)* Implement cross-node VM cloning capability
- *(terraform)* Implement VM tagging system

### 🐛 Bug Fixes

- *(docs)* Correct VM architecture inconsistencies across documentation
- *(network)* Update jumpbox home IP to 192.168.30.240
- *(terraform)* Remove unused ssh_public_key variable and update network defaults
- *(terraform)* Correct Proxmox provider parameter from 'started' to 'on_boot'
- *(terraform)* Add serial device configuration for Debian 12/Ubuntu VMs
- *(terraform)* Add missing root-level variables for VM configuration
- *(terraform)* Correct multi-node deployment understanding and documentation
- *(terraform)* Remove unused variables and clean up configuration
- *(terraform)* Add datastore_id to VM clone configuration
- *(terraform)* Add EFI disk format and QEMU agent configuration

### 💼 Other

- Add Infisical secret management configuration
- Add Claude Code development assistant configuration
- *(docs)* Enhance PRD with comprehensive checklist template for Kubernetes deployment.

### 🚜 Refactor

- *(infra)* [**breaking**] Replace modular terraform with simplified structure
- *(tasks)* Shift from enterprise to learning-focused categories
- *(claude)* Reorganize workflow commands and add new features
- *(terraform)* Restructure to modular architecture
- *(terraform)* Correct infrastructure architecture to 4 VMs
- *(terraform)* Switch to API token authentication for Proxmox provider
- *(terraform)* Implement unified VM deployment with dynamic node assignment

### 📚 Documentation

- *(project)* Update documentation and project configuration
- *(terraform)* Add terraform module documentation
- *(tasks)* Customize task management system for project
- Update Claude agent configurations and commands
- Add planning documentation
- [**breaking**] Archive enterprise-focused documentation
- Create learning-focused documentation
- *(terraform)* Document Proxmox lock errors and mitigation strategies
- *(terraform)* Document VM template availability and EFI disk configuration issues
- *(prep)* Complete PREP-002 with implementation details and troubleshooting

### 🎨 Styling

- *(terraform)* Format terraform files for consistency

### ⚙️ Miscellaneous Tasks

- Add pre-commit hooks and terraform-docs configuration
- Add GitHub Actions workflows for automation
- *(tools)* Configure development tooling and quality assurance
- *(git)* Ignore mise local configuration file
- *(ansible)* Update linting and configuration files
- *(claude)* Remove old workflow command files
- *(claude)* Improve command system with path corrections and date instruction
- *(terraform)* Format and align parameter assignments

### 🛡️ Security

- Add git attributes and enhance gitignore
- Add mise development environment configuration

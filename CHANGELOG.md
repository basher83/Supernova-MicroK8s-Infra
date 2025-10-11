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
- *(ansible)* Add system user management playbooks
- *(mise)* Add task scripts for dependency management
- *(mise)* Enhance configuration with Python venv and new tasks
- *(terraform)* Add multi-node SSH configuration and vendor-data
- *(terraform)* Enhance vendor data with SSH and user configuration
- *(terraform)* Enhance VM module with validations and improved defaults
- *(terraform)* Add comprehensive outputs for Ansible integration
- *(ansible)* Add playbooks for Proxmox template building
- *(scripts)* Add comprehensive Proxmox template builder script
- *(ansible)* Add playbook for enabling VLAN-aware bridging on Proxmox nodes
- *(ansible)* Add playbook for initial MicroK8s installation
- *(ansible)* Add Terraform user provisioning and cloud-init vendor data
- Add BGP routing example configuration
- Change default BIOS from seabios to ovmf (UEFI)
- Add new modular terraform architecture with unified VM modules
- Add Claude AI workspace configuration to repository
- *(ansible)* Enhance MicroK8s roles with production-ready features
- *(terraform)* Enhance unified VM module with advanced features
- *(terraform)* Add vm-cluster module for multi-node deployments
- *(ansible)* Implement ArgoCD role with HTTP/insecure mode configuration
- *(terraform)* Add comprehensive VM template creation support
- *(terraform)* Add active testing deployments

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
- *(ansible)* Update configuration and playbook paths
- *(ansible)* Improve Proxmox Terraform user provisioning playbook
- *(terraform)* Update vm module cloud-init interface default to ide2

### 💼 Other

- Add Infisical secret management configuration
- Add Claude Code development assistant configuration
- *(docs)* Enhance PRD with comprehensive checklist template for Kubernetes deployment.
- *(python)* Add Python dependencies for Ansible development
- Enhance mise tasks and update Python dependencies
- Add OpenTofu 1.10.6 to mise tooling configuration
- Update tooling configuration for OpenTofu and mise improvements

### 🚜 Refactor

- *(infra)* [**breaking**] Replace modular terraform with simplified structure
- *(tasks)* Shift from enterprise to learning-focused categories
- *(claude)* Reorganize workflow commands and add new features
- *(terraform)* Restructure to modular architecture
- *(terraform)* Correct infrastructure architecture to 4 VMs
- *(terraform)* Switch to API token authentication for Proxmox provider
- *(terraform)* Implement unified VM deployment with dynamic node assignment
- *(ansible)* Restructure inventory to use SSH config
- *(ansible)* Delegate connection settings to SSH config
- *(terraform)* Centralize cloud-init vendor data configuration
- *(terraform)* Remove cloud-init vendor data management
- *(scripts)* Enhance inventory generation with Terraform integration
- *(ansible)* Restructure cloud-init snippets for template specialization
- *(ansible)* Update Proxmox template configuration and documentation
- *(terraform)* Replace legacy modules with modular architecture
- Remove legacy terraform modules and root configuration
- Remove legacy Terraform modules
- *(ansible)* Consolidate playbooks and fix role configuration issues
- *(terraform)* Remove deprecated vm-cluster module
- *(terraform)* Apply DRY principles to all deployment examples
- *(terraform)* Apply DRY principles to testing template deployment

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
- *(changelog)* Update changelog for PREP-002 completion
- *(ansible)* Remove uv references and standardize command usage
- Add documentation for ansible commands and terraform files
- *(terraform)* Update README removing outdated template warning
- Add Proxmox command reference and troubleshooting guides
- *(research)* Add comprehensive Proxmox Terraform provider comparison
- *(changelog)* Update changelog with recent infrastructure improvements
- *(changelog)* Update changelog with recent Ansible playbook additions
- Add Terraform user guide and BIOS research, update index
- Add comprehensive project documentation
- Update Proxmox qm command examples
- *(ansible)* Add comprehensive MicroK8s implementation documentation
- *(terraform)* Add comprehensive deployment examples and provisioning guide
- Add troubleshooting guides for common issues
- Add MicroK8s Ansible research report and update documentation index
- Add comprehensive Ansible playbook troubleshooting guide
- *(terraform)* Add DEFAULTS.md reference for vm module
- *(terraform)* Update architecture documentation for for_each pattern
- *(ansible)* Reorganize documentation into ansible subdirectory

### 🎨 Styling

- *(terraform)* Format terraform files for consistency
- *(mise)* Fix indentation in task dependencies

### 🧪 Testing

- Add terraform deployment testing examples

### ⚙️ Miscellaneous Tasks

- Add pre-commit hooks and terraform-docs configuration
- Add GitHub Actions workflows for automation
- *(tools)* Configure development tooling and quality assurance
- *(git)* Ignore mise local configuration file
- *(ansible)* Update linting and configuration files
- *(claude)* Remove old workflow command files
- *(claude)* Improve command system with path corrections and date instruction
- *(terraform)* Format and align parameter assignments
- *(.gitignore)* Add backup entry for .mcp.json file
- *(gitignore)* Clean up Ansible ignore patterns
- *(terraform)* Remove ansible inventory locals from terraform config
- *(terraform)* Remove outputs.tf file
- *(ansible)* Clean up commented configuration paths
- *(terraform)* Update Proxmox provider version to 0.84.1
- *(ansible)* Improve ansible-lint configuration for production quality
- Remove legacy bgp-example directory
- Remove legacy mise-tasks directory
- *(ansible)* Update configuration files and dependencies
- *(ansible)* Improve configuration and inventory structure
- *(terraform)* Remove obsolete testing deployments
- Update ansible playbook and proxmox documentation

### 🛡️ Security

- Add git attributes and enhance gitignore
- Add mise development environment configuration

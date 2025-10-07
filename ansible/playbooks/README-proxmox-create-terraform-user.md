# Proxmox Terraform User Configuration

## Overview

This playbook creates a dedicated `terraform` user on Proxmox nodes for infrastructure automation. It configures both Linux system access (SSH) and Proxmox API access, following the setup documented in [docs/terraform/proxmox-terraform-user.md](../../docs/terraform/proxmox-terraform-user.md).

**Problem Solved**: Terraform needs both SSH access to Proxmox nodes (for file operations) and API access (for VM/container management). This playbook automates the entire user creation and permission setup process.

**Solution**: Creates a `terraform@pam` user in Proxmox with appropriate role-based permissions, SSH key authentication, and passwordless sudo access for required commands.

**Implementation**: Uses a **hybrid approach** combining native Ansible modules with command-line tools:
- **Native modules** (`community.proxmox.*`) for user, group, and ACL management - provides better idempotency and error handling
- **Command-line tools** (`pveum`) for role and API token operations - no native modules available yet

## Reference

- Setup Guide: [docs/terraform/proxmox-terraform-user.md](../../docs/terraform/proxmox-terraform-user.md)
- Terraform Provider: [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

## Prerequisites

### On Control Node (where you run Ansible)

- Ansible installed with access to Proxmox inventory
- Required collection: `community.proxmox` >= 1.0.0
  ```bash
  ansible-galaxy collection install -r requirements.yml
  ```
- Python library: `proxmoxer` (required by `community.proxmox` modules)
  ```bash
  pip3 install proxmoxer
  # or with uv
  uv pip install proxmoxer
  ```
- **Proxmox root password** set in environment variable `PROXMOX_PASSWORD` (required for API authentication)

### On Proxmox Nodes (target hosts)

- SSH access with root/sudo privileges
- SSH public key stored in `ansible/files/terraform_authorized_keys`
- Target: `doggos_cluster` group (holly, lloyd, mable)

## Execution

### Set Required Environment Variable

The playbook requires Proxmox API authentication. Set your root@pam password:

```bash
export PROXMOX_PASSWORD='your-proxmox-root-password'
```

**Security Note**: This password is used to authenticate the `community.proxmox` modules to the Proxmox API. It's needed even though the playbook runs with `become: true` because the modules communicate over the API rather than using local commands.

### Run the Playbook

```bash
cd ansible
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml
```

Or set the password inline (less secure):

```bash
PROXMOX_PASSWORD='your-password' ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml
```

### Check Mode (Dry Run)

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml --check
```

### Target Specific Host

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml --limit holly
```

## What the Playbook Does

### 1. Cleanup Legacy Configuration

- Checks for existing `terraform@pve` user (legacy PVE realm user)
- Deletes `terraform@pve` if found (prevents authentication conflicts)

### 2. Linux User Setup

- Creates Linux user `terraform` with home directory `/home/terraform`
- Configures shell: `/bin/bash`
- Sets up SSH directory and authorized_keys (from `ansible/files/terraform_authorized_keys`)
- Configures sudoers for passwordless access to:
  - `/sbin/pvesm` - Proxmox storage management
  - `/sbin/qm` - QEMU/KVM VM management
  - `/usr/bin/tee /var/lib/vz/*` - Template file operations

### 3. Proxmox API Configuration

#### Using pveum commands:
- Creates `TerraformUser` role with privileges:
  - Datastore operations (Allocate, AllocateSpace, AllocateTemplate, Audit)
  - Pool allocation
  - System operations (Audit, Console, Modify)
  - SDN usage
  - VM operations (full lifecycle management)
  - User modification

#### Using native modules:
- Creates `terraform-users` group (`community.proxmox.proxmox_group`)
- Configures ACL permissions on root path (`community.proxmox.proxmox_access_acl`)
- Creates `terraform@pam` user in PAM realm (`community.proxmox.proxmox_user`)

#### Using pveum commands:
- Generates API token: `terraform@pam!token`

### 4. Verification

- Tests Linux user creation
- Validates passwordless sudo access
- Displays configuration summary and API token

## Expected Output

### Successful First Run

```
TASK [Check if terraform@pve user exists]
ok: [holly]

TASK [Display terraform@pve user check]
ok: [holly] => "msg": "terraform@pve user does not exist"

TASK [Create Linux system user with home directory]
changed: [holly]

TASK [Create TerraformUser role in Proxmox]
changed: [holly]

TASK [Generate API token for terraform@pam]
changed: [holly]

TASK [Display token generation result]
ok: [holly] => {
    "msg": "API Token Generated:\n┌──────────────┬──────────────────────────────────────┐\n│ key          │ value                                │\n╞══════════════╪══════════════════════════════════════╡\n│ full-tokenid │ terraform@pam!token                  │\n├──────────────┼──────────────────────────────────────┤\n│ info         │ {\"privsep\":\"0\"}                      │\n├──────────────┼──────────────────────────────────────┤\n│ value        │ 782a7700-4010-4802-8f4d-820f1b226850 │\n└──────────────┴──────────────────────────────────────┘\n\nIMPORTANT: Save this token - it cannot be retrieved again!"
}
```

### Already Configured

```
TASK [Display user existence status]
ok: [holly] => "msg": "Linux user 'terraform' already exists"

TASK [Display role creation status]
ok: [holly] => "msg": "TerraformUser role already exists"

TASK [Display token generation result]
ok: [holly] => "msg": "API token 'terraform@pam!token' already exists"
```

## Manual Verification

After playbook execution, verify on each Proxmox node:

```bash
# Test SSH access
ssh terraform@holly

# Verify passwordless sudo
sudo -u terraform sudo /sbin/pvesm apiinfo

# Check user in Proxmox
pveum user list | grep terraform

# Verify role permissions
pveum role list | grep TerraformUser

# Check group membership
pveum group list | grep terraform-users

# List API tokens
pveum user token list terraform@pam
```

## Important Notes

### API Token Security

**CRITICAL**: The API token value is only displayed once during generation. You must save it immediately:

```bash
# Full token ID format
terraform@pam!token

# Example token value (save this)
782a7700-4010-4802-8f4d-820f1b226850
```

Store the token securely (e.g., in environment variables, secrets manager, or `terraform.tfvars`).

### SSH Key Setup

Before running the playbook, ensure your SSH public key exists:

```bash
# Create SSH key if needed
ssh-keygen -o -a 100 -t ed25519 -f ~/.ssh/terraform_id_ed25519 -C "terraform@homelab"

# Copy public key to ansible files directory
cp ~/.ssh/terraform_id_ed25519.pub ansible/files/terraform_authorized_keys
```

## Terraform Configuration

After running the playbook, configure Terraform provider:

```hcl
terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.50"
    }
  }
}

provider "proxmox" {
  endpoint = "https://holly.example.com:8006"

  # API authentication
  api_token = "terraform@pam!token=782a7700-4010-4802-8f4d-820f1b226850"

  # SSH authentication (for file operations)
  ssh {
    agent    = true
    username = "terraform"
  }

  insecure = false
  tmp_dir  = "/var/tmp"
}
```

Or use environment variables:

```bash
export PROXMOX_VE_ENDPOINT="https://holly.example.com:8006"
export PROXMOX_VE_API_TOKEN="terraform@pam!token=782a7700-4010-4802-8f4d-820f1b226850"
export PROXMOX_VE_SSH_USERNAME="terraform"
```

## Troubleshooting

### Missing proxmoxer Library

If you see the error: `Failed to import the required Python library (proxmoxer)`

```bash
# Install on control node (where you run ansible-playbook)
pip3 install proxmoxer

# or with uv
uv pip install proxmoxer

# Verify installation
python3 -c "import proxmoxer; print(proxmoxer.__version__)"
```

**Note**: The `community.proxmox` modules run on the control node and make API calls to Proxmox, so `proxmoxer` must be installed on your local machine, not the remote Proxmox hosts.

### Missing PROXMOX_PASSWORD

If you see the error: `one of the following is required: api_password, api_token_id`

```bash
# Set the environment variable
export PROXMOX_PASSWORD='your-proxmox-root-password'

# Verify it's set
echo $PROXMOX_PASSWORD

# Re-run the playbook
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml
```

### API Authentication Failed

If you see authentication errors:

```bash
# Verify you can access the Proxmox API manually
curl -k -d "username=root@pam&password=your-password" https://holly:8006/api2/json/access/ticket

# Check that inventory_hostname resolves correctly
ansible -i inventory/proxmox.yml doggos_cluster -m debug -a "var=inventory_hostname"
```

### Token Already Exists

If the token already exists and you need a new one:

```bash
# Delete existing token
pveum user token delete terraform@pam token

# Re-run playbook to generate new token
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-create-terraform-user.yml
```

### SSH Access Fails

```bash
# Check authorized_keys permissions
ls -la /home/terraform/.ssh/authorized_keys
# Should be: -rw------- (0600)

# Verify SSH key matches
cat /home/terraform/.ssh/authorized_keys
ssh-keygen -lf /home/terraform/.ssh/authorized_keys
```

### Sudo Permission Denied

```bash
# Verify sudoers file exists and is valid
visudo -cf /etc/sudoers.d/terraform

# Test specific commands
sudo -u terraform sudo /sbin/pvesm apiinfo
sudo -u terraform sudo /sbin/qm list
```

### Role Permission Issues

```bash
# Verify role privileges
pveum role show TerraformUser

# Check ACL configuration
pveum acl list | grep terraform-users

# Verify user group membership
pveum user list | grep terraform@pam
```

## Rollback

To remove the configuration:

```bash
# Delete API token
pveum user token delete terraform@pam token

# Delete Proxmox user
pveum user delete terraform@pam

# Delete group (if no other members)
pveum group delete terraform-users

# Delete role (if not used elsewhere)
pveum role delete TerraformUser

# Remove Linux user
userdel -r terraform

# Remove sudoers file
rm /etc/sudoers.d/terraform
```

## Security Considerations

### Least Privilege

- User has only the permissions required for Terraform operations
- Sudo access is restricted to specific commands (not full root)
- API token has privilege separation disabled (`-privsep 0`) for full role permissions

### SSH Key Security

- Uses ed25519 key algorithm (modern, secure)
- Private key should never be shared or committed to version control
- Consider using SSH agent forwarding in CI/CD pipelines

### Token Management

- Tokens should be rotated periodically
- Store tokens in secure secret management systems
- Never commit tokens to version control

## Safety Features

- **Idempotent**: Safe to run multiple times without side effects
- **Validation**: Checks for existing resources before creation
- **Legacy cleanup**: Removes conflicting `terraform@pve` user
- **Verification**: Built-in tests for SSH and sudo access
- **Informative output**: Clear status messages at each step

## Next Steps

After successful execution:

1. **Save API token**: Store securely in secrets manager or environment variables
2. **Test SSH access**: Verify you can SSH as terraform user from your workstation
3. **Configure Terraform**: Update `terraform.tfvars` or provider configuration
4. **Test Terraform**: Run `terraform plan` to verify connectivity
5. **Deploy infrastructure**: Begin provisioning VMs/containers

## Module Information

### Why Hybrid Approach?

This playbook uses both native Ansible modules and command-line tools:

**Native Modules Used** (from `community.proxmox` collection):
- `community.proxmox.proxmox_group` - Group management
  - ✅ Idempotent
  - ✅ Check mode support
  - ✅ Better error handling
- `community.proxmox.proxmox_access_acl` - Permission management
  - ✅ Declarative configuration
  - ✅ Automatic change detection
- `community.proxmox.proxmox_user` - User creation
  - ✅ Proper state management
  - ✅ Clean integration with groups

**Command-Line Tools Used** (`pveum`):
- Role creation - No native module available
- API token generation - No native module available yet
  - Module gap tracked in community.proxmox collection

**Benefits of Hybrid Approach**:
- Maximum idempotency where modules exist
- Full functionality via commands where needed
- Cleaner, more maintainable code
- Better Ansible integration (check mode, handlers, etc.)

### Collection Details

**Required**: `community.proxmox` >= 1.0.0
- **Repository**: https://github.com/ansible-collections/community.proxmox
- **Score**: 72/100 (Tier 2: Good Quality)
- **Status**: Actively maintained, 100+ contributors
- **Latest Release**: v1.3.0 (August 2025)

Install via:
```bash
ansible-galaxy collection install -r requirements.yml
```

## Related Documentation

- [Terraform User Guide](../../docs/terraform/proxmox-terraform-user.md)
- [Terraform Configuration](../../docs/terraform/README-terraform.md)
- [Ansible Standards](../../docs/standards/ansible-standards.md)
- [Ansible Collection Research Report](../../.claude/research-reports/ansible-research-20251006-162853.md)

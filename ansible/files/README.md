# Files Directory

This directory contains static files used by Ansible playbooks.

## terraform_authorized_keys

SSH public keys for the `terraform` user. This file is copied to `/home/terraform/.ssh/authorized_keys` on target hosts.

### Format

Each line should contain one SSH public key in standard OpenSSH format:

```
ssh-ed25519 AAAAC3... comment
ssh-rsa AAAAB3... comment
```

### Adding Keys

To add more SSH keys, simply append them to the file:

```bash
# Add a new key
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINEWKEYgoesHERE..." >> terraform_authorized_keys
```

### Security

- **Do NOT** commit private keys to this repository
- Only public keys (`.pub` files) should be stored here
- The playbook will set proper permissions (0600) when copying to target hosts

### Testing Keys

After adding keys, test SSH access:

```bash
ssh -i ~/.ssh/your_key terraform@target-host sudo pvesm apiinfo
```

## Cloud-Init Snippets

Cloud-Init snippets are used to configure the system during the initial boot. They live on the proxmox node in the `/var/lib/vz/snippets` directory.

### Format

Each line should contain one SSH public key in standard OpenSSH format:

```yaml
#cloud-config
ssh_pwauth: false
timezone: America/New_York
users:
  - name: ansible
    gecos: Ansible User
    groups: users,admin,wheel
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    shell: /bin/bash
    lock_passwd: true
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFa5HX4EzWRRY+YhC979KqYtBPLvTOXtriwzql1uTthp
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL8lJBJBcFUTLgZ9eRx0c/XZau4NxVAdDm1sXMlMd1vL
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKls14HDdv2r2QIhGQfEluBmzrGI2cxjwtdkAWrc4ZRr
package_upgrade: true
packages:
  - qemu-guest-agent

runcmd:
  - [systemctl, enable, --now, qemu-guest-agent]
```

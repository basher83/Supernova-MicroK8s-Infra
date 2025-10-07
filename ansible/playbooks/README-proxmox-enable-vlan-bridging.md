# Proxmox VLAN-Aware Bridging Configuration

## Overview

This playbook enables VLAN-aware bridging on the `vmbr1` network interface across all Proxmox nodes in the `doggos_cluster` (lloyd, mable, holly).

**Problem Solved**: Terraform deployments were timing out due to VLAN filtering not being enabled on Proxmox bridge interfaces. VMs on VLAN 50 couldn't communicate properly.

**Solution**: Enable VLAN-aware bridging by adding `bridge-vlan-aware yes` to the vmbr1 configuration in `/etc/network/interfaces`.

## Reference

- Troubleshooting Guide: [docs/troubleshooting/networking-vlan.md](../../docs/troubleshooting/networking-vlan.md)
- Implementation Phase: **Phase 1 - Enable VLAN-aware bridging**

## Prerequisites

- Ansible installed with `community.general` collection
- SSH access to all Proxmox nodes (lloyd, mable, holly)
- Sudo/root privileges on target hosts

## Execution

### Run the Playbook

```bash
cd ansible
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-enable-vlan-bridging.yml
```

### Check Mode (Dry Run)

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-enable-vlan-bridging.yml --check
```

### Target Specific Host

```bash
ansible-playbook -i inventory/proxmox.yml playbooks/proxmox-enable-vlan-bridging.yml --limit lloyd
```

## What the Playbook Does

1. **Backs up interfaces file**: Creates timestamped backup of `/etc/network/interfaces` (module's built-in backup feature)
2. **Modifies vmbr1 configuration**: Adds `bridge-vlan-aware yes` using `community.general.interfaces_file`
3. **Reloads network configuration**: Executes `ifreload -a` (non-disruptive)
4. **Verifies VLAN filtering**: Runs `bridge vlan show dev vmbr1`

## Expected Output

### Successful Execution

```
TASK [Enable VLAN-aware bridging on vmbr1]
changed: [lloyd]

TASK [Display configuration change status]
ok: [lloyd] => "msg": "VLAN-aware bridging enabled on vmbr1 - network reload required"

RUNNING HANDLER [Reload network interfaces]
changed: [lloyd]

TASK [Verify VLAN filtering is enabled]
ok: [lloyd]

TASK [Display VLAN filtering status]
ok: [lloyd] => {
    "vlan_status.stdout_lines": [
        "port    vlan-id",
        "vmbr1   1 PVID Egress Untagged",
        "vmbr1   50"
    ]
}
```

### Already Configured

```
TASK [Display configuration change status]
ok: [lloyd] => "msg": "VLAN-aware bridging already configured on vmbr1"
```

## Manual Verification

After playbook execution, verify on each Proxmox node:

```bash
# Check bridge VLAN configuration
bridge vlan show dev vmbr1

# Expected output should show VLAN filtering active:
# port    vlan-id
# vmbr1   1 PVID Egress Untagged
# vmbr1   50

# Verify interfaces configuration
grep -A 5 "iface vmbr1" /etc/network/interfaces

# Expected output should include:
# bridge-vlan-aware yes
```

## Rollback

If needed, restore from backup:

```bash
# List available backups (created by interfaces_file module)
ls -lh /etc/network/interfaces.*

# Restore specific backup (replace timestamp)
cp /etc/network/interfaces.12345.2025-01-04@12:30:45~ /etc/network/interfaces

# Reload configuration
ifreload -a
```

## Next Steps

After successful execution:

1. **Verify VM connectivity**: Test that VMs on VLAN 50 can communicate
2. **Run Terraform apply**: Should no longer timeout
3. **Proceed to Phase 2**: Configure VLAN tags on VM network interfaces (if needed)

## Troubleshooting

### Network Reload Fails

```bash
# Check for syntax errors
ifup -n vmbr1

# View detailed network status
networkctl status vmbr1
```

### VLAN Filtering Not Active

```bash
# Manually check bridge state
ip -d link show vmbr1 | grep vlan_filtering

# Expected: vlan_filtering 1
```

### SSH Connection Lost

If connection is lost during network reload (unlikely with `ifreload -a`):

1. Access Proxmox console directly
2. Check `/etc/network/interfaces.*` for backup
3. Restore configuration and reload

## Safety Features

- **Timestamped backups**: Original configuration preserved before changes
- **Idempotent**: Safe to run multiple times
- **Non-disruptive reload**: `ifreload -a` only reloads changed interfaces
- **Surgical modification**: Only touches vmbr1 configuration, leaves other interfaces intact
- **Verification**: Built-in post-execution checks

## Module Choice Rationale

**Why `community.general.interfaces_file`?**

- Purpose-built for Debian/Ubuntu network interfaces
- Modifies specific stanza without touching other configurations
- Built-in timestamped backup feature
- Safer than `ansible.builtin.copy` (which overwrites entire file)
- More maintainable than `ansible.builtin.template` (no full template needed)
- Idempotent and validated

# Archived Playbooks

This directory contains legacy playbooks that have been superseded by the new role-based architecture.

## Archived Files

### playbook-legacy.yml

**Original name:** `playbook.yml`

**Archived reason:** Used raw shell commands instead of Ansible roles. Replaced by `microk8s-deploy.yml` which properly uses:

- `microk8s_install` role
- `microk8s_cluster` role
- `microk8s-addons` role
- `rancher` role
- `argocd` role

**Issues with legacy approach:**

- Shell commands are less idempotent than Ansible modules
- No proper error handling or changed detection
- Difficult to maintain and extend
- Lacked configurability and variable support

### microk8s-initial-install-legacy.yml

**Original name:** `microk8s-initial-install.yml`

**Archived reason:** Duplicated functionality that exists in the `microk8s_install` role. The role provides:

- Configurable MicroK8s version/channel
- Raspberry Pi support
- kubectl/helm alias creation
- CA certificate trust
- Snap autoupdate control
- Better error handling and idempotency

## Current Architecture

All MicroK8s deployment is now handled by `microk8s-deploy.yml` which:

1. Uses proper Ansible Galaxy-standard roles
2. Provides comprehensive variable configuration
3. Implements proper idempotency and error handling
4. Supports tags for selective deployment
5. Includes pre-flight checks and validation

## Migration

If you were using the legacy playbooks, switch to:

```bash
ansible-playbook -i inventory/production.yml playbooks/microk8s-deploy.yml
```

For partial deployments, use tags:

```bash
# Install only
ansible-playbook -i inventory/production.yml playbooks/microk8s-deploy.yml --tags install

# Cluster formation only
ansible-playbook -i inventory/production.yml playbooks/microk8s-deploy.yml --tags cluster

# Addons only
ansible-playbook -i inventory/production.yml playbooks/microk8s-deploy.yml --tags addons
```

## Reference

See the main Ansible README and role documentation for detailed usage instructions.

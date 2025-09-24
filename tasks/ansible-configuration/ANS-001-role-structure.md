---
Task: Create proper Ansible role structure for MicroK8s configuration management
Task ID: ANS-001
Priority: P0
Estimated Time: 2 hours
Dependencies: TER-005
Status: ⏸️ Blocked
Created: 2025-09-20
Updated: 2025-09-20
---

## Objective

Transform the existing basic Ansible playbook structure into a professional, modular role-based architecture with proper error handling, idempotency, and secret management capabilities.

## Prerequisites

- [ ] TER-005 completed (Development environment ready for testing)
- [ ] Ansible 2.9+ installed
- [ ] ansible-lint installed for validation
- [ ] Access to existing `ansible/` directory for reference

## Implementation Steps

### 1. **Create Ansible Role Directory Structure**

```bash
# Create base ansible structure
cd ansible/
mkdir -p {roles,group_vars,host_vars,playbooks,inventory}

# Create role directories
mkdir -p roles/{microk8s_base,microk8s_ha,rancher,argocd}/{tasks,handlers,templates,defaults,vars,meta}

# Create group variables structure
mkdir -p group_vars/{all,masters,workers}

# Create additional support directories
mkdir -p {library,filter_plugins,scripts}
```

### 2. **Configure Ansible Configuration**

Create `ansible/ansible.cfg`:

```ini
[defaults]
inventory = inventory/
roles_path = roles/
host_key_checking = False
retry_files_enabled = False
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_cache
fact_caching_timeout = 3600
stdout_callback = yaml
callback_whitelist = profile_tasks

[ssh_connection]
pipelining = True
control_path = /tmp/ansible-%%h-%%p-%%r
```

### 3. **Create Base Role Structure**

Create `ansible/roles/microk8s_base/tasks/main.yml`:

```yaml
---
# MicroK8s base installation tasks

- name: Include OS-specific variables
  include_vars: "{{ ansible_os_family }}.yml"
  tags: [always]

- name: Check if MicroK8s is installed
  command: snap list microk8s
  register: microk8s_installed
  changed_when: false
  failed_when: false
  tags: [microk8s]

- name: Install MicroK8s if not present
  block:
    - name: Install MicroK8s snap
      community.general.snap:
        name: microk8s
        classic: true
        channel: "{{ microk8s_channel | default('1.28/stable') }}"
      when: microk8s_installed.rc != 0

    - name: Wait for MicroK8s to be ready
      command: microk8s status --wait-ready
      retries: 10
      delay: 30
      register: result
      until: result.rc == 0

  tags: [microk8s, install]

- name: Configure MicroK8s user permissions
  user:
    name: "{{ microk8s_user }}"
    groups: microk8s
    append: yes
  tags: [microk8s, users]

- name: Create kubectl alias
  lineinfile:
    path: "/home/{{ microk8s_user }}/.bashrc"
    line: "alias kubectl='microk8s kubectl'"
    create: yes
  tags: [microk8s, alias]
```

Create `ansible/roles/microk8s_base/defaults/main.yml`:

```yaml
---
# Default variables for microk8s_base role

microk8s_channel: "1.28/stable"
microk8s_user: "{{ ansible_user | default('ubuntu') }}"
microk8s_addons:
  - dns
  - storage
  - ingress

# Cluster configuration
cluster_domain: cluster.local
max_pods_per_node: 250
```

### 4. **Create Group Variables**

Create `ansible/group_vars/all/main.yml`:

```yaml
---
# Global variables for all hosts

# SSH configuration
ansible_user: ubuntu
ansible_ssh_common_args: '-o StrictHostKeyChecking=no'

# MicroK8s configuration
microk8s_version: "1.28"
enable_ha: true

# Network configuration
cluster_subnet: "192.168.10"
dns_servers:
  - 8.8.8.8
  - 8.8.4.4
```

Create `ansible/group_vars/all/vault.yml`:

```bash
# Create encrypted vault file for sensitive data
ansible-vault create ansible/group_vars/all/vault.yml
```

Add to vault file:

```yaml
---
# Encrypted sensitive variables
vault_rancher_password: "super-secret-password"
vault_argocd_password: "another-secret"
vault_cluster_token: "secure-cluster-join-token"
```

### 5. **Create Site Playbook**

Create `ansible/playbooks/site.yml`:

```yaml
---
# Main site playbook for MicroK8s deployment

- name: Deploy MicroK8s Base
  hosts: all
  become: yes
  roles:
    - microk8s_base
  tags: [base]

- name: Configure HA Cluster
  hosts: masters
  become: yes
  roles:
    - microk8s_ha
  tags: [ha]

- name: Deploy Rancher
  hosts: masters[0]
  become: yes
  roles:
    - rancher
  tags: [rancher]
  when: deploy_rancher | default(false)

- name: Deploy ArgoCD
  hosts: masters[0]
  become: yes
  roles:
    - argocd
  tags: [argocd]
  when: deploy_argocd | default(false)
```

## Success Criteria

- [ ] Proper Ansible role directory structure created
- [ ] Roles follow Ansible best practices
- [ ] Idempotent tasks that can be run multiple times
- [ ] Error handling and retries implemented
- [ ] Ansible vault configured for secrets
- [ ] Variables properly organized in group_vars/host_vars

## Validation

```bash
# Check directory structure
tree ansible/roles -L 2

# Validate playbook syntax
cd ansible/
ansible-playbook playbooks/site.yml --syntax-check

# Lint the roles
ansible-lint roles/

# Test with check mode
ansible-playbook playbooks/site.yml --check

# Verify vault encryption
ansible-vault view group_vars/all/vault.yml
```

Expected output:
- Clean directory structure matching Ansible best practices
- No syntax errors in playbooks
- No lint warnings (or only minor ones)
- Check mode runs without errors

## Notes

- Use community.general collection for snap module
- Keep sensitive data in ansible-vault encrypted files
- Use tags for selective execution
- Implement proper error handling with blocks
- Make all tasks idempotent

## References

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- Existing playbook in `ansible/playbooks/playbook.yml`
- [Planning Document](../../docs/planning.md) - Ansible Integration section
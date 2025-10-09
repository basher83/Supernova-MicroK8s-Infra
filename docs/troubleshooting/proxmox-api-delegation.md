# Proxmox API Module Delegation Issues

Common issues when using `community.proxmox.*` modules with `delegate_to: localhost`.

## Issue 1: Connection Refused to localhost:8006

### Symptoms

```
[ERROR]: Task failed: Module failed: Couldn't authenticate user: root@pam to https://localhost:8006/api2/json/access/ticket
fatal: [host -> localhost]: FAILED! => {"msg": "HTTPSConnectionPool(host='localhost', port=8006): Max retries exceeded"}
```

### Root Cause

When using `delegate_to: localhost` with Proxmox modules, the `ansible_host` variable changes context to localhost instead of the target Proxmox node. This causes the module to try connecting to `localhost:8006` instead of the actual Proxmox host IP.

**Problematic pattern:**

```yaml
vars:
  proxmox_api_host: "{{ ansible_host | default(inventory_hostname) }}"

tasks:
  - name: Create group
    community.proxmox.proxmox_group:
      api_host: "{{ proxmox_api_host }}"
      # ...
    delegate_to: localhost  # ansible_host becomes localhost!
```

### Solution

Use `hostvars[inventory_hostname]` to preserve the original host's context when delegating:

```yaml
vars:
  proxmox_api_host: "{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}"
  # Alternative if ansible_host is set in inventory:
  # proxmox_api_host: "{{ hostvars[inventory_hostname]['ansible_host'] }}"
```

**Key points:**
- Requires `gather_facts: true` to collect `ansible_default_ipv4`
- Works without hardcoding IPs in inventory
- Correctly resolves IP even when delegated to localhost

## Issue 2: Authentication Failure with Infisical Secrets

### Symptoms

Authentication works with `infisical run` but fails in Ansible:

```
[ERROR]: Task failed: Module failed: Couldn't authenticate user: root@pam to https://192.168.10.2:8006
```

Debug shows wrong password length or base64 value.

### Root Causes

#### 2A: Stale Environment Variables

Ansible's `lookup('env', 'VAR')` checks environment variables **before** falling back to Infisical. Old values from `.mise.local.toml` or shell exports take precedence.

**Check for stale vars:**

```bash
echo "PROXMOX_PASSWORD: ${#PROXMOX_PASSWORD} chars"
ansible localhost -m debug -a "msg={{ lookup('env', 'PROXMOX_PASSWORD') }}"
```

**Solution:**

```bash
# Unset in current shell
unset PROXMOX_PASSWORD PROXMOX_USERNAME

# Or run playbook with clean environment
env -u PROXMOX_PASSWORD -u PROXMOX_USERNAME ansible-playbook playbook.yml

# Or start fresh shell session
exit  # and reopen terminal
```

#### 2B: Whitespace in Infisical Secrets

Infisical secrets may contain leading/trailing whitespace that breaks authentication.

**Solution:**

Add `| trim` filter in `infisical-secret-lookup.yml`:

```yaml
- name: "infisical-secret-lookup | Retrieve secret from Infisical"
  ansible.builtin.set_fact:
    "{{ secret_var_name }}": >-
      {{ lookup('infisical.vault.read_secrets', ...).value | trim }}
```

### Verification

Compare credentials between Infisical and Ansible:

```bash
# From Infisical directly
infisical run --projectId="..." --env="prod" --path="/path" -- bash -c \
  'echo "Password: $(echo -n "$PROXMOX_PASSWORD" | base64)"'

# From Ansible playbook (add debug task)
- name: Debug credentials
  ansible.builtin.debug:
    msg: "Password: {{ proxmox_password | b64encode }}"
```

Base64 values should match exactly.

## Issue 3: Module Parameter Errors

### Symptoms

```
[ERROR]: Task failed: Module failed: Invalid parameters
```

Or unexpected behavior (module not finding existing resources).

### Root Cause

`community.proxmox.*` modules have specific parameter requirements that differ from what you might expect. The module documentation in `ansible-doc` is definitive.

### Common Module Issues

#### proxmox_access_acl

**Wrong:**

```yaml
- name: Configure ACL
  community.proxmox.proxmox_access_acl:
    path: /
    roles: ["RoleName"]           # ❌ Not an array
    groups: ["group-name"]        # ❌ Not an array
```

**Correct:**

```yaml
- name: Configure ACL
  community.proxmox.proxmox_access_acl:
    path: /
    type: group                   # ✅ 'user', 'group', or 'token'
    ugid: "group-name"            # ✅ User/group/token ID
    roleid: "RoleName"            # ✅ Single role name
```

#### proxmox_user

**Wrong:**

```yaml
- name: Create user
  community.proxmox.proxmox_user:
    name: "terraform"             # ❌ Missing realm
    realm: "pam"                  # ❌ No separate realm parameter
```

**Correct:**

```yaml
- name: Create user
  community.proxmox.proxmox_user:
    userid: "terraform@pam"       # ✅ Format: username@realm
    # OR
    name: "terraform@pam"         # ✅ 'name' is alias for 'userid'
```

### Debugging Strategy

1. **Check `ansible-doc`:**

   ```bash
   ansible-doc community.proxmox.proxmox_user
   ansible-doc community.proxmox.proxmox_access_acl | grep -A 30 "EXAMPLES:"
   ```

2. **Read module source code:**

   ```bash
   # Find module location
   find ~/.ansible/collections -name "proxmox_user.py"

   # Check DOCUMENTATION and EXAMPLES sections
   cat ~/.ansible/collections/ansible_collections/community/proxmox/plugins/modules/proxmox_user.py
   ```

3. **Look for:**
   - Required parameters
   - Parameter aliases (`userid` vs `name`)
   - Expected data types (string vs list vs dict)
   - Example usage patterns

See [ansible-module-parameters.md](./ansible-module-parameters.md) for detailed debugging guide.

## Issue 4: PAM User 500 Error

### Symptoms

```
[ERROR]: Task failed: Module failed: Unable to retrieve user terraform@pam:
500 Internal Server Error: no such user ('terraform@pam')
```

### Root Cause

The `proxmox_user` module calls the Proxmox API to check if a PAM user exists. Proxmox returns a `500 Internal Server Error` for non-existent PAM users instead of a proper `404 Not Found`. The module doesn't handle this gracefully.

This is a quirk specific to PAM realm users. PVE realm users return proper error codes.

### Solution

Use `pveum` command instead of the module for PAM user creation:

```yaml
- name: Check if PAM user exists
  ansible.builtin.command: pveum user list
  register: proxmox_users
  changed_when: false

- name: Create PAM user with pveum
  ansible.builtin.command: >
    pveum user add {{ username }}@pam
    --groups {{ group_name }}
    --comment "{{ comment }}"
  when: "username + '@pam' not in proxmox_users.stdout"
```

**Why this works:**
- `pveum user list` returns all users without errors
- Simple string search avoids API quirks
- Direct command is more reliable for PAM realm

**Note:** The `proxmox_user` module works fine for:
- Updating existing PAM users
- Creating/managing PVE realm users
- Other realms (LDAP, etc.)

## Complete Working Example

```yaml
- name: Configure Proxmox with API modules
  hosts: proxmox_nodes
  gather_facts: true  # Required for ansible_default_ipv4

  vars:
    # Infisical configuration
    infisical_project_id: 'your-project-id'
    infisical_env: 'prod'
    infisical_path: '/proxmox'

    # API connection - uses gathered facts
    proxmox_api_host: "{{ hostvars[inventory_hostname]['ansible_default_ipv4']['address'] }}"
    proxmox_api_user: "{{ proxmox_username }}"      # From Infisical
    proxmox_api_password: "{{ proxmox_password }}"  # From Infisical
    proxmox_validate_certs: false

  pre_tasks:
    # Retrieve credentials from Infisical
    - name: Get Proxmox username
      ansible.builtin.include_tasks: tasks/infisical-secret-lookup.yml
      vars:
        secret_name: 'PROXMOX_USERNAME'
        secret_var_name: 'proxmox_username'
        fallback_env_var: 'PROXMOX_USERNAME'

    - name: Get Proxmox password
      ansible.builtin.include_tasks: tasks/infisical-secret-lookup.yml
      vars:
        secret_name: 'PROXMOX_PASSWORD'
        secret_var_name: 'proxmox_password'
        fallback_env_var: 'PROXMOX_PASSWORD'

  tasks:
    # Works correctly with delegation
    - name: Create group
      community.proxmox.proxmox_group:
        name: "my-group"
        api_host: "{{ proxmox_api_host }}"
        api_user: "{{ proxmox_api_user }}"
        api_password: "{{ proxmox_api_password }}"
        validate_certs: "{{ proxmox_validate_certs }}"
      delegate_to: localhost
      become: false

    # Use pveum for PAM users
    - name: Check existing users
      ansible.builtin.command: pveum user list
      register: user_list
      changed_when: false

    - name: Create PAM user
      ansible.builtin.command: >
        pveum user add myuser@pam
        --groups my-group
      when: "'myuser@pam' not in user_list.stdout"
```

## Quick Troubleshooting Checklist

When Proxmox API modules fail:

- [ ] Is `gather_facts: true` set?
- [ ] Does `proxmox_api_host` use `hostvars[inventory_hostname]`?
- [ ] Are environment variables overriding Infisical secrets?
- [ ] Do module parameters match `ansible-doc` examples?
- [ ] Is `delegate_to: localhost` and `become: false` set?
- [ ] For PAM users, using `pveum` instead of `proxmox_user`?
- [ ] Are credentials correct (test with curl/infisical run)?

## Related Documentation

- [Ansible Module Parameter Debugging](./ansible-module-parameters.md)
- [community.proxmox collection](https://docs.ansible.com/ansible/latest/collections/community/proxmox/)
- [Proxmox VE API Reference](https://pve.proxmox.com/pve-docs/api-viewer/)

# Ansible Playbook Troubleshooting

This document covers issues discovered during the playbook refactoring and testing, along with their solutions.

## Overview

During the migration from legacy shell-based playbooks to role-based architecture, several pre-existing bugs were discovered in the Ansible roles. All issues have been fixed and validated.

**Status**: ✅ All issues resolved

---

## Issue #1: Malformed IP Regex in microk8s_cluster Role

### Problem

**File**: `ansible/roles/microk8s_cluster/defaults/main.yml:14`

Cluster formation failed when joining nodes with this error:

```
fatal: [microk8s-2 -> microk8s-1]: FAILED! =>
{"cmd": "set -o pipefail && microk8s add-node | grep -E -m1 'microk8s join ([0-9]{1,3}[\\.])3}[0-9]{1,3}'",
"rc": 1, "msg": "non-zero return code"}
```

### Root Cause

The IP address regex pattern had a malformed repetition operator:

```yaml
# ❌ BROKEN - missing opening brace before {3}
microk8s_ip_regex_ha: "([0-9]{1,3}[\\.])3}[0-9]{1,3}"
                                        ^^^ Should be {3}
```

The `{3}` repetition was missing its opening brace, causing the grep filter to fail when extracting the join command.

### Solution

Fixed the regex pattern to properly match IPv4 addresses:

```yaml
# ✅ FIXED - proper IPv4 regex pattern
microk8s_ip_regex_ha: "([0-9]{1,3}\\.){3}[0-9]{1,3}"
```

**Commit**: Fixed in playbook refactoring commit

### Verification

```bash
# Test the regex pattern
echo "microk8s join 192.168.10.101:25000/token" | grep -E 'microk8s join ([0-9]{1,3}\.){3}[0-9]{1,3}'
# Should match successfully

ansible-lint roles/microk8s_cluster/
# Should pass with 0 errors
```

---

## Issue #2: Boolean Conditional Error in microk8s-addons Role

### Problem

**File**: `ansible/roles/microk8s-addons/tasks/main.yml:32`

Addon enablement failed with this error:

```
[ERROR]: Task failed: Conditional result (True) was derived from value of type 'str'
at '/Users/.../ansible/roles/microk8s-addons/defaults/main.yml:26:13'.
Conditionals must have a boolean result.

failed: [microk8s-1] (item=registry)
```

### Root Cause

The conditional checked a string value directly as truthy, which newer Ansible versions reject:

```yaml
when:
  - item.name in microk8s_plugins
  - microk8s_plugins[item.name]  # ❌ String "size=20Gi" evaluated as truthy
  - microk8s_plugins[item.name] is string
```

Ansible was trying to evaluate the string `"size=20Gi"` as a boolean, which is not allowed.

### Solution

Reordered conditions to check type first, then use explicit length check:

```yaml
when:
  - item.name in microk8s_plugins
  - microk8s_plugins[item.name] is string        # ✅ Check type first
  - microk8s_plugins[item.name] | length > 0     # ✅ Explicit non-empty check
  - microk8s_plugins[item.name] != 'true'
  - microk8s_plugins[item.name] != 'True'
```

**Commit**: Fixed in playbook refactoring commit

### Verification

```bash
ansible-lint roles/microk8s-addons/
# Should pass with 0 errors

ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags addons --check
# Should not fail on conditional checks
```

---

## Issue #3: Incorrect Disable Logic in microk8s-addons Role

### Problem

**File**: `ansible/roles/microk8s-addons/tasks/main.yml:64`

The playbook tried to disable DNS addon, causing cluster failure:

```
[DEPRECATION WARNING]: The `bool` filter coerced invalid value '8.8.8.8,8.8.4.4' (str) to False.

failed: [microk8s-1] (item=dns) => {"msg": "non-zero return code", "rc": 1,
"stderr": "error: timed out waiting for the condition on pods/coredns-5986966c54-rg9fd"}
```

### Root Cause

The disable logic incorrectly converted string parameters to `False`:

```yaml
when:
  - item.status == 'enabled'
  - item.name in microk8s_plugins
  - not microk8s_plugins[item.name] | bool  # ❌ String "8.8.8.8,8.8.4.4" → False
```

When DNS has value `"8.8.8.8,8.8.4.4"`, the `| bool` filter coerces it to `False`, so `not False` = `True`, triggering an unwanted disable.

### Solution

Only disable explicitly boolean-typed addons set to `false`:

```yaml
when:
  - item.status == 'enabled'
  - item.name in microk8s_plugins
  - microk8s_plugins[item.name] is boolean  # ✅ Check it's a boolean first
  - not microk8s_plugins[item.name]         # ✅ Then check if False
```

**Commit**: Fixed in playbook refactoring commit

### How It Works Now

| Addon Config | Type | Behavior |
|--------------|------|----------|
| `dns: "8.8.8.8,8.8.4.4"` | String | ✅ **Won't disable** (parameter addon) |
| `registry: "size=20Gi"` | String | ✅ **Won't disable** (parameter addon) |
| `prometheus: false` | Boolean | ✅ **Will disable** (explicitly disabled) |
| `ingress: true` | Boolean | ✅ **Won't disable** (enabled) |

### Verification

```bash
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags addons
# DNS should remain enabled with string parameters
```

---

## Issue #4: Pre-task Checks Failing with Tag-Based Execution

### Problem

**File**: `ansible/playbooks/microk8s-deploy.yml:103-110` (original)

Running `--tags rancher` or `--tags argocd` failed with:

```
fatal: [microk8s-1]: FAILED! =>
{"assertion": "microk8s_plugins.dns is defined", "evaluated_to": false,
"msg": "Rancher requires dns, ingress, and helm3 addons to be enabled"}
```

### Root Cause

Pre-task checks relied on `microk8s_plugins` variables that are only loaded when the addons play runs. When using tags to skip plays, those variables were undefined:

```yaml
# ❌ BROKEN - relies on variables from potentially skipped plays
pre_tasks:
  - name: Ensure required addons are enabled for Rancher
    ansible.builtin.assert:
      that:
        - microk8s_plugins.dns is defined      # ← Undefined when addons play is skipped
        - microk8s_plugins.ingress is defined
```

### Solution

Changed to query the actual cluster state instead of relying on playbook variables:

```yaml
# ✅ FIXED - checks actual cluster status
pre_tasks:
  - name: Get current MicroK8s addon status
    ansible.builtin.command:
      cmd: "microk8s status --format yaml"
    register: rancher_addon_check
    changed_when: false

  - name: Parse addon status
    ansible.builtin.set_fact:
      cluster_addons_status: "{{ rancher_addon_check.stdout | from_yaml }}"

  - name: Check required addons for Rancher
    ansible.builtin.assert:
      that:
        - cluster_addons_status.addons | selectattr('name', 'equalto', 'dns') | selectattr('status', 'equalto', 'enabled') | list | length > 0
        - cluster_addons_status.addons | selectattr('name', 'equalto', 'ingress') | selectattr('status', 'equalto', 'enabled') | list | length > 0
      fail_msg: "Rancher requires dns, ingress, helm3, and cert-manager addons to be enabled."
```

**Commit**: Fixed in playbook refactoring commit

### Verification

```bash
# Should now work with any tag combination
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags rancher
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags argocd
```

---

## Issue #5: Recursive Template Loop in Role Defaults

### Problem

**Files**:
- `ansible/roles/rancher/defaults/main.yml:15`
- `ansible/roles/argocd/defaults/main.yml:12`

Rancher and ArgoCD deployment failed with:

```
[ERROR]: Task failed: Recursive loop detected in template: maximum recursion depth exceeded
Origin: /Users/.../ansible/roles/rancher/defaults/main.yml:15:19

15 rancher_hostname: "{{ rancher_hostname | default('rancher.local') }}"
                      ^ column 19
```

### Root Cause

Both roles had variables that referenced themselves, creating infinite recursion:

```yaml
# ❌ BROKEN - infinite recursion!
rancher_hostname: "{{ rancher_hostname | default('rancher.local') }}"
                      ^^^^^^^^^^^^^^^ references itself!

argocd_hostname: "{{ argocd_hostname | default('argocd.local') }}"
                     ^^^^^^^^^^^^^^ references itself!
```

### Solution

Changed to simple default values (Ansible's variable precedence handles overrides automatically):

```yaml
# ✅ FIXED - Rancher
rancher_hostname: "rancher.local"

# ✅ FIXED - ArgoCD
argocd_hostname: "argocd.local"
```

**Commit**: Fixed in playbook refactoring commit

### How Variable Precedence Works

With the fix, variables can still be overridden in order of precedence:

1. **Extra vars** (`-e rancher_hostname=custom.domain`) - highest priority
2. **Playbook vars**
3. **Inventory vars** (host_vars, group_vars)
4. **Role defaults** (the fixed values) - lowest priority

So `group_vars/all.yml` values like `rancher_hostname: "rancher.ansible"` will still override these defaults.

### Verification

```bash
ansible-lint roles/rancher/ roles/argocd/
# Should pass with 0 errors

ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags rancher --check
# Should not fail on recursive template
```

---

## Issue #6: Missing cert-manager Dependency for Rancher

### Problem

**File**: `ansible/roles/microk8s-addons/defaults/main.yml:79`

Rancher installation failed with:

```
Error: INSTALLATION FAILED: unable to build kubernetes objects from release manifest:
resource mapping not found for name: "rancher" namespace: "" from "":
no matches for kind "Issuer" in version "cert-manager.io/v1"
ensure CRDs are installed first
```

### Root Cause

Rancher requires cert-manager CRDs (Custom Resource Definitions) to manage TLS certificates, but cert-manager addon was **disabled by default**:

```yaml
# ❌ Problem - cert-manager disabled by default
cert-manager: false
```

### Solution

**1. Enabled cert-manager by default** in addon configuration:

```yaml
# ✅ FIXED - cert-manager enabled (required for Rancher)
cert-manager: true
```

**2. Added cert-manager to Rancher pre-task checks**:

```yaml
- name: Check required addons for Rancher
  ansible.builtin.assert:
    that:
      - cluster_addons_status.addons | selectattr('name', 'equalto', 'dns') | ...
      - cluster_addons_status.addons | selectattr('name', 'equalto', 'ingress') | ...
      - cluster_addons_status.addons | selectattr('name', 'equalto', 'helm3') | ...
      - cluster_addons_status.addons | selectattr('name', 'equalto', 'cert-manager') | ...  # ✅ Added
    fail_msg: "Rancher requires dns, ingress, helm3, and cert-manager addons..."
```

**Commit**: Fixed in playbook refactoring commit

### Required Addons for Rancher

| Addon | Purpose | Default |
|-------|---------|---------|
| `dns` | CoreDNS for service discovery | ✅ Enabled |
| `ingress` | Ingress controller for external access | ✅ Enabled |
| `helm3` | Helm package manager | ✅ Enabled |
| `cert-manager` | Certificate management (TLS/SSL) | ✅ Enabled |

### Verification

```bash
# cert-manager should be enabled
microk8s status | grep cert-manager
# Should show: cert-manager: enabled

ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags rancher
# Should succeed with cert-manager enabled
```

---

## Issue #7: Undefined Variables in Final Summary

### Problem

**File**: `ansible/playbooks/microk8s-deploy.yml:168-200` (original)

When running with `--tags install`, the final summary failed:

```
[ERROR]: Task failed: 'rancher_hostname' is undefined
fatal: [microk8s-1]: FAILED! => {"msg": "Task failed: 'rancher_hostname' is undefined"}
```

### Root Cause

The final summary task (tagged `always`) referenced service variables that are only defined when their respective plays run:

```yaml
# ❌ BROKEN - variables undefined when plays are skipped
- name: Display final deployment summary
  ansible.builtin.debug:
    msg: |
      Services Deployed:
      - Rancher: https://{{ rancher_hostname }}    # ← Undefined if rancher play skipped
      - ArgoCD: https://{{ argocd_hostname }}      # ← Undefined if argocd play skipped
```

### Solution

Added conditional Jinja2 templates to only show services when variables are defined:

```yaml
# ✅ FIXED - conditional display based on variable existence
- name: Display final deployment summary
  ansible.builtin.debug:
    msg: |
      ========================================
      MicroK8s Cluster Deployment Complete!
      ========================================

      Cluster Nodes:
      {{ cluster_nodes.stdout }}
      {% if rancher_hostname is defined or argocd_hostname is defined %}

      Services Deployed:
      {% if rancher_hostname is defined %}
      - Rancher (Cluster Management): https://{{ rancher_hostname }}
      {% endif %}
      {% if argocd_hostname is defined %}
      - ArgoCD (GitOps): https://{{ argocd_hostname }}
      {% endif %}
      ...
      {% endif %}
```

**Commit**: Fixed in playbook refactoring commit

### Behavior with Different Tags

| Tags Used | Summary Shows |
|-----------|---------------|
| `--tags install` | Cluster status only |
| `--tags install,cluster` | Cluster status only |
| `--tags addons` | Cluster status only |
| `--tags rancher` | Cluster status + Rancher URL |
| `--tags argocd` | Cluster status + ArgoCD URL |
| Full deployment | Cluster status + all services |

### Verification

```bash
# Should work with any tag combination
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags install
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml --tags rancher
ansible-playbook -i inventory/testing.yml playbooks/microk8s-deploy.yml
```

---

---

## Issue #8: ArgoCD Ingress Configuration Issues

### Problem

**Files**:
- `ansible/roles/argocd/defaults/main.yml`
- `ansible/roles/argocd/tasks/main.yml`

ArgoCD ingress access failed with multiple issues during deployment:

1. **LoadBalancer stuck pending**: Service type was `LoadBalancer` but MicroK8s doesn't have MetalLB enabled
2. **Redirect loop (ERR_TOO_MANY_REDIRECTS)**: nginx ingress misconfigured for HTTPS backend
3. **SSL Passthrough not working**: MicroK8s nginx-ingress controller doesn't have `--enable-ssl-passthrough` flag enabled
4. **Port mismatch**: Ingress routing to port 443 instead of port 80
5. **Hostname reversion**: Helm chart kept reverting ingress hostname from `argocd.local` to `argocd.example.com`
6. **Insecure mode not applied**: Helm values for `configs.params.server.insecure` didn't update the configmap

### Root Cause

Multiple configuration issues with ArgoCD Helm chart and MicroK8s limitations:

```yaml
# ❌ BROKEN - Service waiting for LoadBalancer IP
argocd_service_type: "LoadBalancer"

# ❌ BROKEN - SSL passthrough doesn't work (nginx controller not configured)
argocd_ingress_ssl_passthrough: true

# ❌ BROKEN - Helm values don't set configmap properly
--set configs.params."server.insecure"=true
```

The MicroK8s nginx-ingress controller is deployed without the `--enable-ssl-passthrough` flag, so SSL passthrough annotations are ignored. The ArgoCD Helm chart also has issues where:
- Ingress resources don't get updated during `helm upgrade`
- The `configs.params.server.insecure` Helm value doesn't properly update the `argocd-cmd-params-cm` configmap
- Ingress hostname defaults to `argocd.example.com` regardless of Helm values

### Solution

**1. Changed service type to ClusterIP** (ingress handles external access):

```yaml
# ✅ FIXED - Use ClusterIP when ingress is enabled
argocd_service_type: "ClusterIP"
```

**2. Disabled SSL passthrough** (not supported by MicroK8s nginx):

```yaml
# ✅ FIXED - Use HTTP/insecure mode instead
argocd_ingress_ssl_passthrough: false
```

**3. Configured insecure mode via direct configmap patch**:

```yaml
- name: Configure ArgoCD server insecure mode (required for HTTP ingress)
  become: true
  ansible.builtin.command:
    cmd: >
      microk8s kubectl patch configmap argocd-cmd-params-cm -n argocd
      --type='json'
      -p='[{"op":"add","path":"/data/server.insecure","value":"true"}]'
  when: argocd_current_insecure.stdout | default('') != 'true'
  register: argocd_insecure_config
```

**4. Added restart task** to apply insecure mode:

```yaml
- name: Restart ArgoCD server to apply insecure mode
  become: true
  ansible.builtin.command:
    cmd: microk8s kubectl rollout restart deployment argocd-server -n argocd
  when: argocd_insecure_config is changed
```

**5. Added ingress patch** to fix hostname and port:

```yaml
- name: Patch ingress hostname and annotations if needed
  become: true
  ansible.builtin.command:
    cmd: >
      microk8s kubectl patch ingress argocd-server -n argocd
      --type='json'
      -p='[
        {"op": "replace", "path": "/spec/rules/0/host", "value":"argocd.local"},
        {"op": "replace", "path": "/spec/rules/0/http/paths/0/backend/service/port/number", "value":80}
      ]'
  when: >
    (argocd_current_hostname.stdout | default('') != argocd_hostname) or
    (argocd_current_backend_port.stdout | default('') != '80')
```

**6. Added annotation task** to ensure HTTP backend:

```yaml
- name: Ensure ingress annotations are set correctly for HTTP backend
  become: true
  ansible.builtin.command:
    cmd: >
      microk8s kubectl annotate ingress argocd-server -n argocd
      nginx.ingress.kubernetes.io/backend-protocol=HTTP
      nginx.ingress.kubernetes.io/ssl-passthrough=false
      nginx.ingress.kubernetes.io/force-ssl-redirect=false
      --overwrite
  when: argocd_ingress_enabled and not argocd_ingress_ssl_passthrough
```

**Commit**: Fixed in ArgoCD troubleshooting fixes

### How It Works Now

| Configuration | Value | Purpose |
|--------------|-------|---------|
| Service Type | `ClusterIP` | No LoadBalancer needed - ingress handles access |
| Server Mode | `insecure=true` | ArgoCD serves HTTP on port 8080 (exposed as 80) |
| Ingress Backend | Port 80, HTTP | nginx routes HTTP traffic to ArgoCD |
| Ingress Hostname | `argocd.local` | Patched directly (Helm doesn't update properly) |
| SSL Passthrough | `false` | Not supported by MicroK8s nginx-ingress |
| Access URL | `http://argocd.local` | HTTP access (not HTTPS) |

**Traffic Flow:**
1. User accesses `http://argocd.local`
2. nginx ingress controller routes to `argocd-server:80`
3. ArgoCD serves HTTP on port 8080 (exposed as service port 80)
4. User sees ArgoCD UI

### Verification

```bash
# Check service type
microk8s kubectl get svc argocd-server -n argocd
# Should show: TYPE=ClusterIP

# Check ingress configuration
microk8s kubectl get ingress argocd-server -n argocd -o yaml
# Should show:
#   host: argocd.local
#   backend port: 80
#   annotations:
#     nginx.ingress.kubernetes.io/backend-protocol: HTTP
#     nginx.ingress.kubernetes.io/ssl-passthrough: "false"

# Check insecure mode
microk8s kubectl get configmap argocd-cmd-params-cm -n argocd -o yaml
# Should show: server.insecure: "true"

# Access ArgoCD
curl -I http://argocd.local
# Should return 200 OK
```

### Why SSL Passthrough Doesn't Work

MicroK8s nginx-ingress controller is deployed without the `--enable-ssl-passthrough` flag:

```bash
# Check controller args
microk8s kubectl get daemonset -n ingress nginx-ingress-microk8s-controller -o yaml | grep args: -A 10

# Output shows NO --enable-ssl-passthrough flag:
# - /nginx-ingress-controller
# - --configmap=$(POD_NAMESPACE)/nginx-load-balancer-microk8s-conf
# - --ingress-class=public
```

Without this flag, SSL passthrough annotations are ignored, forcing us to use HTTP/insecure mode instead.

### Alternative: Enable SSL Passthrough (Not Recommended)

If HTTPS access is required, you would need to:

1. Edit the nginx-ingress DaemonSet to add `--enable-ssl-passthrough` flag
2. Set `argocd_ingress_ssl_passthrough: true`
3. Configure ingress for port 443 and HTTPS backend
4. Access via `https://argocd.local`

However, this requires modifying the MicroK8s ingress addon directly and may be overwritten during MicroK8s upgrades.

---

## Summary

All issues have been fixed and validated:

| Issue | File | Status |
|-------|------|--------|
| Malformed IP regex | `roles/microk8s_cluster/defaults/main.yml` | ✅ Fixed |
| Boolean conditional error | `roles/microk8s-addons/tasks/main.yml` | ✅ Fixed |
| Incorrect disable logic | `roles/microk8s-addons/tasks/main.yml` | ✅ Fixed |
| Pre-task checks with tags | `playbooks/microk8s-deploy.yml` | ✅ Fixed |
| Recursive template loop | `roles/rancher/defaults/main.yml`, `roles/argocd/defaults/main.yml` | ✅ Fixed |
| Missing cert-manager | `roles/microk8s-addons/defaults/main.yml` | ✅ Fixed |
| Undefined variables in summary | `playbooks/microk8s-deploy.yml` | ✅ Fixed |
| ArgoCD ingress configuration | `roles/argocd/defaults/main.yml`, `roles/argocd/tasks/main.yml` | ✅ Fixed |

**Validation Status**:
- ✅ All roles pass `ansible-lint` with production profile
- ✅ All playbooks pass `ansible-playbook --syntax-check`
- ✅ Tag-based execution works correctly
- ✅ Full deployment tested and working
- ✅ Rancher accessible at `https://rancher.local`
- ✅ ArgoCD accessible at `http://argocd.local`

## Prevention

To prevent similar issues in the future:

1. **Always test with tags**: Test playbooks with various tag combinations, not just full runs
2. **Avoid self-referencing variables**: Use simple defaults and rely on Ansible's variable precedence
3. **Check cluster state, not variables**: For pre-task validation, query actual cluster state
4. **Type-check before value-check**: When using conditionals, check data types before evaluating values
5. **Use conditional templates**: For output tasks, use `{% if var is defined %}` to handle skipped plays
6. **Test regex patterns**: Validate regex patterns with actual test data before using in production
7. **Run ansible-lint regularly**: Catch issues early with `ansible-lint` in pre-commit hooks

## Related Documentation

- [Ansible Standards](../standards/ansible-standards.md) - Best practices and patterns
- [MicroK8s Implementation](../ansible/microk8s-implementation-enhancements.md) - Role architecture
- [Module Parameters](ansible-module-parameters.md) - Common module issues

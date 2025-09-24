---
Task: Develop comprehensive vendor data configuration for MicroK8s automated installation
Task ID: TER-002
Priority: P0
Estimated Time: 4 hours
Dependencies: TER-001
Status: ⏸️ Blocked
Created: 2025-09-20
Updated: 2025-09-20
---

## Objective

Create vendor data snippets for Proxmox that automatically install and configure MicroK8s on VM boot, following the existing vendor_data pattern from `infrastructure/modules/vm/` while adapting for MicroK8s requirements.

## Prerequisites

- [ ] TER-001 completed (base structure exists)
- [ ] Understanding of cloud-init/vendor data format
- [ ] Access to existing vendor_data examples in `infrastructure/`
- [ ] MicroK8s installation requirements documented

## Implementation Steps

### 1. **Create Base Vendor Data Template**

Create `infrastructure-microk8s/vendor-data/microk8s-base.yaml`:

```yaml
#cloud-config
# MicroK8s base installation vendor data

# System updates and packages
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - curl
  - jq
  - ca-certificates
  - gnupg
  - lsb-release
  - linux-modules-extra-$(uname -r)
  - net-tools
  - nfs-common

# Kernel modules and system configuration
write_files:
  - path: /etc/sysctl.d/99-kubernetes.conf
    content: |
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1
      vm.swappiness = 0
      fs.inotify.max_user_instances = 8192
      fs.inotify.max_user_watches = 524288

  - path: /etc/modules-load.d/kubernetes.conf
    content: |
      br_netfilter
      overlay
      ip_vs
      ip_vs_rr
      ip_vs_wrr
      ip_vs_sh

runcmd:
  # Enable QEMU guest agent
  - systemctl enable --now qemu-guest-agent

  # Apply kernel parameters
  - modprobe br_netfilter
  - modprobe overlay
  - sysctl --system

  # Disable swap
  - swapoff -a
  - sed -i '/ swap / s/^/#/' /etc/fstab

  # Install MicroK8s
  - snap install microk8s --classic --channel=${microk8s_channel}
  - microk8s status --wait-ready

  # Configure user permissions
  - usermod -a -G microk8s ${ssh_username}
  - chown -f -R ${ssh_username} ~/.kube
```

### 2. **Create Master-Specific Configuration**

Create `infrastructure-microk8s/vendor-data/microk8s-master.yaml`:

```yaml
#cloud-config
# MicroK8s master node configuration

# Include base configuration
merge_type: 'list(append)+dict(recurse_array)+str()'

write_files:
  - path: /var/snap/microk8s/current/args/kube-apiserver
    append: true
    content: |
      --enable-admission-plugins=NodeRestriction,ResourceQuota
      --audit-log-maxsize=100
      --audit-log-maxbackup=10
      --service-node-port-range=30000-32767

  - path: /var/snap/microk8s/current/args/kubelet
    append: true
    content: |
      --cluster-domain=cluster.local
      --max-pods=250
      --resolv-conf=/run/systemd/resolve/resolv.conf

  - path: /etc/microk8s/ha-conf
    content: |
      %{ if ha_enabled }
      failure-domain: ${failure_domain}
      %{ endif }

runcmd:
  # Additional master configuration
  - |
    if [ "${is_primary_master}" = "true" ]; then
      # Generate cluster token for joining
      microk8s add-node --token ${cluster_token} --token-ttl 3600 > /tmp/join-command.txt

      # Enable essential addons on primary master only
      sleep 30
      microk8s enable dns:${dns_server}
      microk8s enable storage
      microk8s enable ingress
    fi
```

### 3. **Create Worker-Specific Configuration**

Create `infrastructure-microk8s/vendor-data/microk8s-worker.yaml`:

```yaml
#cloud-config
# MicroK8s worker node configuration

# Include base configuration
merge_type: 'list(append)+dict(recurse_array)+str()'

write_files:
  - path: /var/snap/microk8s/current/args/kubelet
    append: true
    content: |
      --cluster-domain=cluster.local
      --max-pods=250
      --node-labels=node-role.kubernetes.io/worker=true

runcmd:
  # Worker-specific configuration
  - |
    # Wait for master to be ready
    sleep 60

    # Join the cluster using provided token
    if [ -n "${join_command}" ]; then
      ${join_command}
    fi
```

### 4. **Integrate with Terraform Module**

Update `infrastructure-microk8s/modules/microk8s-vm/main.tf`:

```hcl
# Create vendor data snippet on target node
resource "proxmox_virtual_environment_file" "vendor_data" {
  content_type = "snippets"
  datastore_id = var.datastore_id
  node_name    = var.vm_node_name

  source_raw {
    file_name = "${var.vm_name}-vendor.yaml"
    data = templatefile(
      var.node_role == "master"
        ? "${path.module}/../../vendor-data/microk8s-master.yaml"
        : "${path.module}/../../vendor-data/microk8s-worker.yaml",
      {
        microk8s_channel    = var.microk8s_channel
        ssh_username        = var.ssh_username
        cluster_token       = var.cluster_token
        is_primary_master   = var.is_primary_master
        ha_enabled          = var.ha_enabled
        failure_domain      = var.failure_domain
        dns_server          = var.dns_server
        join_command        = var.join_command
      }
    )
  }
}
```

## Success Criteria

- [ ] Vendor data templates created for base, master, and worker configurations
- [ ] Kernel parameters and system settings properly configured
- [ ] MicroK8s installation automated via snap
- [ ] User permissions and groups configured
- [ ] Master/worker role differentiation implemented
- [ ] Template variables properly defined

## Validation

```bash
# Validate YAML syntax
yamllint infrastructure-microk8s/vendor-data/*.yaml

# Test template rendering
cd infrastructure-microk8s/modules/microk8s-vm
terraform console
# Test templatefile() function with sample variables

# Verify cloud-init compatibility
cloud-init devel schema --config-file vendor-data/microk8s-base.yaml
```

Expected output:
- No YAML syntax errors
- Valid cloud-init schema
- Successful template rendering

## Notes

- Keep vendor data files under 16KB (Proxmox snippet limit)
- Use template variables for environment-specific values
- Ensure idempotent operations for potential re-runs
- Test incrementally - start with base, then add complexity

## References

- [Cloud-init Documentation](https://cloudinit.readthedocs.io/)
- [MicroK8s Installation Guide](https://microk8s.io/docs/install-alternatives)
- Existing vendor data in `infrastructure/modules/vm/main.tf`
- [Planning Document](../../docs/planning.md) - Vendor Data Configuration section
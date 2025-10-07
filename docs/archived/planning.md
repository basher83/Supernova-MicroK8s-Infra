# MicroK8s Infrastructure Integration Plan

## Overview

This document outlines the comprehensive plan to integrate multiple sources of infrastructure code into a unified, automated MicroK8s deployment system for Proxmox. The goal is to combine the sophisticated patterns from existing infrastructure code with MicroK8s deployment logic from GitHub sources.

## Current State Analysis

### Repository Structure Assessment

- **`terraform/`**: Basic Proxmox VM provisioning for K8s nodes (master/worker setup)
  - Simple, hardcoded approach without cloud-init
  - Lacks SSH key management and modular structure
  - Direct IP configuration without sophisticated patterns

- **`ansible/`**: Complete MicroK8s installation and HA cluster setup (includes Rancher and ArgoCD)
  - Functionally complete but uses basic shell commands
  - Lacks idempotency checks and proper error handling
  - Missing ansible vault for sensitive data

- **`infrastructure/`**: Sophisticated terraform patterns (Vault/Nomad setup - unrelated to MicroK8s)
  - Uses vendor_data snippets for cloud-init (not traditional cloud-init)
  - Modular design with multi-environment support
  - Proper state management and node distribution for HA
  - Well-organized with clear separation of concerns

- **`scripts/`**: Basic automation utilities (inventory generation, documentation)
  - Existing inventory generation can be adapted
  - Good foundation for automation pipeline

### Key Issues Identified

1. **Architecture Mismatch**: `infrastructure/` contains Vault/Nomad code, not MicroK8s
2. **Missing Integration**: No connection between terraform VM provisioning and ansible configuration
3. **Pattern Inconsistency**: `terraform/` lacks cloud-init and sophisticated patterns from `infrastructure/`
4. **Security Gaps**: Missing SSH key management, sensitive data handling, and network segmentation
5. **Ansible Quality**: Playbooks lack idempotency, error handling, and proper module usage

## Integration Strategy

### Vision

Create a **unified, automated MicroK8s deployment pipeline** that combines:

- Sophisticated terraform patterns (cloud-init, modular design, multi-environment support)
- MicroK8s deployment logic (installation, HA setup, addons)
- Modern infrastructure-as-code practices for maintainable deployments

### Target Architecture

```
📁 Supernova-MicroK8s-Infra/
├── 📁 infrastructure-microk8s/           # New MicroK8s-focused terraform (initially separate)
│   ├── 📁 environments/
│   │   ├── 📁 development/              # Dev environment (single-node testing)
│   │   ├── 📁 staging/                 # Staging environment (3-node HA)
│   │   └── 📁 production/              # Prod environment (5+ node HA)
│   ├── 📁 modules/
│   │   ├── 📁 microk8s-vm/             # Base MicroK8s VM module
│   │   ├── 📁 microk8s-master/         # Master-specific configuration
│   │   └── 📁 microk8s-worker/         # Worker-specific configuration
│   └── 📁 vendor-data/                  # Vendor data snippets for MicroK8s
├── 📁 ansible/                          # Enhanced ansible configuration
│   ├── 📁 inventory/                    # Auto-generated from terraform
│   ├── 📁 roles/                        # Proper ansible roles structure
│   │   ├── 📁 microk8s-base/          # Base MicroK8s installation
│   │   ├── 📁 microk8s-ha/            # HA cluster formation
│   │   ├── 📁 rancher/                # Rancher deployment
│   │   └── 📁 argocd/                 # ArgoCD deployment
│   ├── 📁 group_vars/                  # Environment-specific variables
│   └── 📁 playbooks/
│       ├── site.yml                    # Main playbook
│       └── validate.yml                # Cluster validation playbook
├── 📁 scripts/                          # Enhanced automation
│   ├── deploy.sh                       # End-to-end deployment
│   ├── validate-cluster.sh             # Cluster health checks
│   └── generate-inventory.sh           # Terraform to Ansible bridge
├── 📁 infrastructure/                   # Archive (Vault/Nomad reference)
└── 📁 docs/
    ├── 📝 blueprint.md                 # Updated with new approach
    ├── 📝 deployment-guide.md          # Comprehensive guide
    └── 📝 troubleshooting.md           # Common issues and solutions
```

## Implementation Plan

### Phase 1: Foundation

#### Step 1: Create New Terraform Structure

- **Create `infrastructure-microk8s/`** directory (keep original for reference)
- **Migrate vendor_data patterns** from `infrastructure/` (not traditional cloud-init)
- **Implement modular design** with separate master/worker modules
- **Add proper variable typing** and validation
- **Create environment-specific** configurations with proper sizing:
  - Development: 1 master (testing)
  - Staging: 3 masters (HA testing)
  - Production: 3+ masters, 2+ workers

#### Step 2: Build MicroK8s Vendor Data Configuration

- **Adapt existing vendor_data approach** for MicroK8s (maintain consistency)
- **Include automated setup** for:
  - Ubuntu base configuration and updates
  - MicroK8s snap installation with specific version
  - Kernel parameters (ip_forward, bridge-nf-call-iptables)
  - Disable swap for Kubernetes
  - Configure systemd-resolved for K8s DNS
  - SSH key injection and hardening
  - Network optimization for container runtime
  - QEMU guest agent for Proxmox integration
- **Add node-specific configurations**:
  - Master nodes: API server settings, etcd optimization
  - Worker nodes: Kubelet settings, container runtime tuning

#### Step 3: Enhance Ansible Configuration

- **Refactor to proper ansible roles** structure:
  - Convert shell commands to ansible modules where possible
  - Add idempotency checks for all operations
  - Implement proper error handling and retries
  - Use ansible vault for sensitive data (passwords, tokens)
- **Update inventory generation** script to:
  - Parse terraform outputs correctly
  - Generate dynamic groups (masters, workers)
  - Include host variables (node roles, IPs)
- **Create validation playbooks** for:
  - Cluster health checks
  - Network connectivity tests
  - MicroK8s addon status
- **Preserve and enhance** Rancher and ArgoCD workflows:
  - Use helm ansible module instead of shell
  - Add wait conditions for deployments
  - Implement proper secret management

### Phase 2: Integration

#### Step 4: Implement Environment Configurations

- **Development environment**:
  - 1 master node (2 vCPU, 4GB RAM, 40GB disk)
  - Single network interface
  - Basic addons (dns, storage)
  - For rapid iteration and testing
- **Staging environment**:
  - 3 master nodes (4 vCPU, 8GB RAM, 60GB disk)
  - HA configuration with automatic failover
  - Full addon suite (dns, ingress, metallb, storage, cert-manager)
  - Network segmentation testing
- **Production environment**:
  - 3+ master nodes (4 vCPU, 8GB RAM, 100GB disk)
  - 2+ worker nodes (8 vCPU, 16GB RAM, 200GB disk)
  - Full HA with node distribution across Proxmox hosts
  - Complete addon suite with monitoring
  - Network segmentation with VLANs

#### Step 5: Create Enhanced Deployment Pipeline

- **Pre-flight checks**:
  - Validate Proxmox connectivity
  - Check template availability
  - Verify network configuration
  - Confirm SSH keys
- **Deployment pipeline** (`scripts/deploy.sh`):
  ```bash
  terraform plan → terraform apply →
  generate inventory → validate connectivity →
  ansible-playbook site.yml → validate cluster →
  run smoke tests → generate report
  ```
- **Rollback procedures**:
  - Terraform state snapshots
  - Ansible recovery playbooks
  - Cluster backup/restore scripts
- **Monitoring integration**:
  - Prometheus metrics collection
  - Grafana dashboard provisioning

#### Step 6: Update Documentation

- **Revise blueprint.md** with new automated approach
- **Create deployment guide** with step-by-step instructions
- **Document architecture** and component relationships
- **Add troubleshooting** and maintenance guides

### Phase 3: Migration and Cleanup

#### Step 7: Safe Migration Strategy

- **Create feature branch** for all changes
- **Archive `infrastructure/`** to `infrastructure-vault-archive/`
- **Test `infrastructure-microk8s/`** thoroughly before replacing
- **Use terraform workspaces** for safer state management
- **Maintain backward compatibility** during transition

#### Step 8: Comprehensive Testing

- **Unit Testing**:
  - Test terraform modules individually
  - Validate vendor_data snippets
  - Test ansible roles in isolation
- **Integration Testing**:
  - Single-node deployment validation
  - HA cluster formation testing
  - Network connectivity verification
  - Addon installation validation
- **End-to-End Testing**:
  - Complete deployment pipeline
  - Failover scenarios
  - Load testing with sample applications
  - Disaster recovery procedures
- **Security Validation**:
  - SSH key authentication
  - Network segmentation
  - RBAC configuration
  - Secret management

## Technical Specifications

### Enhanced Terraform Module Design

```hcl
# Main module structure maintaining your sophisticated patterns
module "microk8s_master" {
  source = "../../modules/microk8s-master"

  # VM Configuration
  vm_name         = "microk8s-master-${count.index + 1}"
  vm_id           = local.vm_id_offset + 100 + count.index
  vm_node_name    = local.node_assignments[count.index]  # Distribute across Proxmox nodes

  # Resource allocation
  vcpu            = var.master_specs.vcpu
  vcpu_type       = "host"  # Use host CPU type for performance
  memory          = var.master_specs.memory
  disk_size       = var.master_specs.disk

  # Network Configuration
  vm_ip_primary   = "${var.cluster_subnet}.${10 + count.index}/24"
  vm_gateway      = "${var.cluster_subnet}.1"
  vm_bridge_1     = var.vm_bridge_cluster
  vm_bridge_2     = var.enable_management_network ? var.vm_bridge_mgmt : ""
  enable_dual_network = var.enable_management_network

  # MicroK8s Configuration via vendor_data
  microk8s_version = var.microk8s_version
  microk8s_channel = var.microk8s_channel
  cluster_token    = random_password.cluster_token.result
  enable_ha        = count.index < 3  # First 3 nodes are HA masters

  # Security
  ci_ssh_key       = var.ci_ssh_key
  ssh_username     = var.ssh_username

  # Tags for organization
  vm_tags = concat(
    var.common_tags,
    [
      local.env_tag,
      "microk8s-master",
      local.node_assignments[count.index],
      "k8s-${var.microk8s_version}"
    ]
  )
}

# Secure cluster token generation
resource "random_password" "cluster_token" {
  length  = 32
  special = false
}

# Variable structure following your patterns
variable "microk8s_cluster" {
  type = object({
    version = string
    channel = string
    addons  = list(string)
    masters = object({
      count  = number
      vcpu   = number
      memory = number
      disk   = number
    })
    workers = object({
      count  = number
      vcpu   = number
      memory = number
      disk   = number
    })
  })

  validation {
    condition     = var.microk8s_cluster.masters.count >= 1
    error_message = "At least one master node is required."
  }
}
```

### Vendor Data Configuration (Maintaining Your Style)

```yaml
#cloud-config
# MicroK8s vendor data for Proxmox - maintains your existing pattern

# System updates and base packages
package_update: true
package_upgrade: true
packages:
  - qemu-guest-agent
  - curl
  - jq
  - ca-certificates
  - gnupg
  - lsb-release
  - linux-modules-extra-$(uname -r)  # Required for some K8s features

# System configuration for Kubernetes
write_files:
  - path: /etc/sysctl.d/99-kubernetes.conf
    content: |
      net.bridge.bridge-nf-call-iptables = 1
      net.bridge.bridge-nf-call-ip6tables = 1
      net.ipv4.ip_forward = 1
      vm.swappiness = 0

  - path: /etc/modules-load.d/kubernetes.conf
    content: |
      br_netfilter
      overlay

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

  # Install MicroK8s with specific version
  - snap install microk8s --classic --channel=${microk8s_channel}

  # Add user to microk8s group
  - usermod -a -G microk8s ${ssh_username}

  # Configure MicroK8s for production
  - echo "--cluster-domain=cluster.local" >> /var/snap/microk8s/current/args/kubelet
  - echo "--max-pods=250" >> /var/snap/microk8s/current/args/kubelet

  # For master nodes: configure API server
  %{ if node_role == "master" }
  - echo "--enable-admission-plugins=NodeRestriction,ResourceQuota" >> /var/snap/microk8s/current/args/kube-apiserver
  - echo "--audit-log-maxsize=100" >> /var/snap/microk8s/current/args/kube-apiserver
  - echo "--audit-log-maxbackup=10" >> /var/snap/microk8s/current/args/kube-apiserver
  %{ endif }

  # Wait for MicroK8s to be ready
  - microk8s status --wait-ready

  # Store join token if master
  %{ if node_role == "master" && is_primary_master }
  - microk8s add-node --token ${cluster_token} --token-ttl 3600 > /tmp/join-token.txt
  %{ endif }
```

### Enhanced Ansible Integration

```yaml
# Proper ansible role structure
roles/
  microk8s-base/
    tasks/
      main.yml      # Base MicroK8s setup
      validate.yml  # Health checks
    handlers/
      main.yml      # Service restarts
    defaults/
      main.yml      # Default variables

  microk8s-ha/
    tasks/
      main.yml      # HA cluster formation
      join.yml      # Node joining logic
    templates/
      ha-conf.j2    # HA configuration

# Example of improved ansible task (idempotent, proper modules)
- name: Check if MicroK8s is installed
  command: snap list microk8s
  register: microk8s_installed
  changed_when: false
  failed_when: false

- name: Install MicroK8s
  community.general.snap:
    name: microk8s
    classic: true
    channel: "{{ microk8s_channel }}"
  when: microk8s_installed.rc != 0

- name: Wait for MicroK8s to be ready
  command: microk8s status --wait-ready
  retries: 10
  delay: 30
  register: result
  until: result.rc == 0

# Proper secret management with ansible-vault
- name: Configure Rancher with encrypted password
  kubernetes.core.helm:
    name: rancher
    namespace: cattle-system
    chart_ref: rancher-latest/rancher
    values:
      hostname: "{{ rancher_hostname }}"
      bootstrapPassword: "{{ vault_rancher_password }}"
    wait: true
    wait_timeout: 600
```

## Success Metrics

### Functional Requirements

- [ ] Automated VM provisioning via terraform
- [ ] Automated MicroK8s installation via cloud-init
- [ ] HA cluster formation and validation
- [ ] Rancher installation and configuration
- [ ] ArgoCD deployment and setup
- [ ] Multi-environment support (dev/staging/prod)

### Non-Functional Requirements

- [ ] Infrastructure as Code best practices
- [ ] Modular and reusable components
- [ ] Comprehensive documentation
- [ ] Automated deployment pipeline
- [ ] Error handling and rollback procedures

## Revised Timeline (More Realistic)

### Phase 1: Foundation (Week 1-3)

- **Week 1**: Terraform Structure
  - Day 1-2: Create `infrastructure-microk8s/` directory structure
  - Day 3-4: Develop base VM module with vendor_data
  - Day 5-7: Create master/worker specific modules

- **Week 2**: Vendor Data & Testing
  - Day 1-3: Build comprehensive vendor_data configurations
  - Day 4-5: Test single-node deployment
  - Day 6-7: Iterate based on testing results

- **Week 3**: Ansible Enhancement
  - Day 1-3: Refactor to proper ansible roles
  - Day 4-5: Add idempotency and error handling
  - Day 6-7: Implement ansible-vault for secrets

### Phase 2: Integration (Week 4-5)

- **Week 4**: Environment Setup
  - Day 1-2: Development environment configuration
  - Day 3-4: Staging environment with HA
  - Day 5-7: Production environment with full features

- **Week 5**: Automation & Documentation
  - Day 1-3: Create deployment pipeline scripts
  - Day 4-5: Validation and smoke test scripts
  - Day 6-7: Update all documentation

### Phase 3: Migration and Testing (Week 6-7)

- **Week 6**: Migration
  - Day 1-2: Archive existing infrastructure
  - Day 3-4: Final integration testing
  - Day 5-7: Performance optimization

- **Week 7**: Production Readiness
  - Day 1-3: Security validation
  - Day 4-5: Disaster recovery testing
  - Day 6-7: Final review and sign-off

## Risk Assessment

### High Risk

- **Terraform State Migration**:
  - Risk: Potential data loss during restructuring
  - Mitigation: Use workspaces, backup state files, test in dev first
- **Vendor Data Complexity**:
  - Risk: Boot failures due to misconfiguration
  - Mitigation: Incremental testing, fallback configurations
- **Network Segmentation**:
  - Risk: Connectivity issues between nodes
  - Mitigation: Start with single network, add segmentation gradually

### Medium Risk

- **Ansible Playbook Compatibility**:
  - Risk: Breaking changes in existing workflows
  - Mitigation: Maintain backward compatibility, thorough testing
- **MicroK8s Version Compatibility**:
  - Risk: Addon incompatibilities
  - Mitigation: Pin versions, test upgrade paths
- **SSH Key Management**:
  - Risk: Access issues during deployment
  - Mitigation: Multiple key options, recovery procedures

### Low Risk

- **Documentation Drift**:
  - Risk: Docs out of sync with implementation
  - Mitigation: Documentation as code, automated generation
- **Performance Tuning**:
  - Risk: Suboptimal cluster performance
  - Mitigation: Iterative optimization, monitoring

## Migration Strategy

### Backup and Safety

1. **Git Branching**: Create feature branch for all changes
2. **State Backup**: Backup terraform state before migration
3. **Gradual Rollout**: Test in development environment first
4. **Rollback Plan**: Document steps to revert changes if needed

### Testing Approach

1. **Unit Testing**: Test individual components in isolation
2. **Integration Testing**: Test terraform + ansible workflow
3. **End-to-End Testing**: Complete deployment pipeline validation
4. **Performance Testing**: Load testing and optimization

## Enhanced Deployment Pipeline

### Complete Deployment Flow

```bash
#!/bin/bash
# deploy.sh - End-to-end MicroK8s cluster deployment

set -euo pipefail

# Configuration
ENVIRONMENT="${1:-development}"
TERRAFORM_DIR="infrastructure-microk8s/environments/${ENVIRONMENT}"
ANSIBLE_DIR="ansible"

# Pre-flight checks
echo "🔍 Running pre-flight checks..."
./scripts/preflight-check.sh || exit 1

# Terraform deployment
echo "🏗️ Deploying infrastructure with Terraform..."
cd "${TERRAFORM_DIR}"
terraform init -upgrade
terraform plan -out=tfplan
terraform apply tfplan

# Generate ansible inventory
echo "📝 Generating Ansible inventory..."
cd "${PROJECT_ROOT}"
./scripts/generate-inventory.sh "${ENVIRONMENT}"

# Wait for VMs to be ready
echo "⏳ Waiting for VMs to be accessible..."
./scripts/wait-for-vms.sh

# Run ansible playbooks
echo "🔧 Configuring cluster with Ansible..."
cd "${ANSIBLE_DIR}"
ansible-playbook -i inventory/${ENVIRONMENT}.yml \
  playbooks/site.yml \
  --vault-password-file=.vault-pass

# Validate cluster
echo "✅ Validating cluster health..."
ansible-playbook -i inventory/${ENVIRONMENT}.yml \
  playbooks/validate.yml

# Run smoke tests
echo "🧪 Running smoke tests..."
./scripts/smoke-tests.sh "${ENVIRONMENT}"

# Generate report
echo "📊 Generating deployment report..."
./scripts/generate-report.sh "${ENVIRONMENT}"

echo "✨ Deployment complete!"
```

### Validation Steps

```yaml
# validate.yml - Cluster validation playbook
---
- name: Validate MicroK8s Cluster
  hosts: masters[0]
  tasks:
    - name: Check cluster status
      command: microk8s status
      register: cluster_status

    - name: Verify HA status
      command: microk8s status | grep "high-availability: yes"
      when: groups['masters'] | length >= 3

    - name: Check all nodes are ready
      shell: microk8s kubectl get nodes -o json
      register: nodes_json

    - name: Verify addon status
      command: microk8s status | grep -E "(dns|ingress|storage|metallb)"
      register: addons_status

    - name: Test cluster DNS
      shell: |
        microk8s kubectl run test-dns --image=busybox:1.28 --rm -it --restart=Never -- \
        nslookup kubernetes.default

    - name: Generate health report
      template:
        src: health-report.j2
        dest: /tmp/cluster-health-{{ ansible_date_time.epoch }}.txt
```

## Critical Integration Points

### 1. Terraform → Ansible Bridge
- Terraform outputs include: VM IPs, hostnames, roles
- Script parses outputs and generates ansible inventory
- Includes group_vars with environment-specific settings

### 2. SSH Key Management
- Terraform injects keys via vendor_data
- Ansible uses same keys for configuration
- Backup keys stored in secure vault

### 3. Network Configuration
- Consistent subnet allocation across environments
- MetalLB IP ranges reserved per environment
- DNS configuration automated

### 4. Secret Management Flow
```
Terraform (random_password) →
Ansible Vault (encrypted storage) →
Kubernetes Secrets (runtime)
```

## Next Steps

1. **Week 1 Priority Actions**:
   - Create `infrastructure-microk8s/` directory structure
   - Develop base terraform module with vendor_data
   - Set up development Proxmox template

2. **Week 2-3 Goals**:
   - Complete vendor_data configurations
   - Refactor ansible to proper roles
   - Single-node deployment working

3. **Week 4-5 Targets**:
   - All three environments configured
   - Deployment pipeline fully automated
   - Documentation complete

4. **Week 6-7 Completion**:
   - Production-ready cluster deployment
   - All tests passing
   - Monitoring and alerting configured

## Key Recommendations Summary

### Must-Have Changes
1. **Use vendor_data** instead of traditional cloud-init (maintains your pattern)
2. **Create separate `infrastructure-microk8s/`** initially (safer migration)
3. **Refactor ansible to proper roles** (improves maintainability)
4. **Add comprehensive error handling** (production readiness)
5. **Implement proper secret management** (security requirement)

### Architecture Improvements
1. **Modular terraform design** with master/worker separation
2. **Environment-specific configurations** with proper sizing
3. **Network segmentation** capability (start simple, add complexity)
4. **Automated validation** at every stage
5. **Disaster recovery** procedures built-in

### Process Enhancements
1. **Extended timeline** (7 weeks vs 5 weeks)
2. **Incremental testing** approach
3. **Feature branch** development
4. **Comprehensive documentation** as code
5. **Monitoring from day one**

## Conclusion

This integration plan transforms scattered infrastructure code into a cohesive, automated MicroK8s deployment system. By combining the best practices from existing sources, we create a maintainable and scalable solution for homelab Kubernetes infrastructure.

The plan emphasizes gradual implementation with comprehensive testing, ensuring a smooth transition from the current mixed state to a unified, production-ready deployment system.

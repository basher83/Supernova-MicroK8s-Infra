# Ansible Infrastructure Automation

## Overview

**Modular, flexible Ansible automation** for deploying production-ready MicroK8s Kubernetes clusters on Proxmox. Supports both simple 3-node HA clusters and scalable architectures with dedicated worker nodes.

### Key Design Principles

✨ **Modular Architecture**: Separate roles for installation, clustering, and addons
🔄 **Flexible Scaling**: Start with 3 nodes, add workers anytime
🎯 **Production-Grade**: HA cluster formation with idempotent operations
🔐 **Secrets Management**: Infisical integration with environment fallbacks
📦 **Galaxy Standard**: All roles follow Ansible Galaxy structure

---

## Directory Structure

```text
ansible/
├── ansible.cfg              # Ansible configuration (inventory, SSH, caching)
├── requirements.yml         # Required Ansible collections
├── group_vars/
│   └── all.yml             # Global variables (network, hosts, services)
├── inventory/              # Inventory configurations
│   ├── production.yml      # Production environment inventory (3-node cluster)
│   └── proxmox.yml         # Proxmox dynamic inventory config
├── playbooks/              # Orchestration playbooks
│   ├── playbook.yml        # Main: MicroK8s + Rancher + ArgoCD deployment
│   ├── microk8s-initial-install.yml
│   ├── add-system-user.yml
│   ├── proxmox-*.yml       # Proxmox infrastructure setup
│   └── examples/           # Pattern demonstrations and working examples
├── roles/                  # Reusable automation components (Galaxy standard)
│   ├── microk8s_install/   # ✅ Enhanced: Base installation with certs & user mgmt
│   ├── microk8s_cluster/   # ✅ Enhanced: HA cluster formation (istvano patterns)
│   ├── microk8s-addons/    # ✅ Enhanced: 30+ addons with idempotent management
│   ├── rancher/            # Rancher deployment via Helm
│   └── argocd/             # ArgoCD deployment via Helm
├── tasks/                  # Reusable task files
│   └── infisical-secret-lookup.yml  # Advanced secret retrieval patterns
└── files/                  # Static files (cloud-init, SSH keys)
```

---

## Quick Start

### Prerequisites

```bash
# Set Infisical credentials (required for secrets)
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="..."
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="..."

# Install Ansible collections
ansible-galaxy collection install -r requirements.yml
```

### Deployment Options

#### Option 1: Simple 3-Node HA Cluster (Recommended)

```bash
# Deploy 3-node HA cluster with MicroK8s, Rancher, and ArgoCD
ansible-playbook playbooks/playbook.yml
```

**Inventory** (production.yml):
```yaml
all:
  children:
    microk8s:
      hosts:
        microk8s-1:
        microk8s-2:
        microk8s-3:
```

#### Option 2: 3-Node HA + Worker Nodes (Scalable)

```yaml
all:
  children:
    microk8s:              # HA control-plane nodes
      hosts:
        microk8s-1:
        microk8s-2:
        microk8s-3:
    microk8s_workers:      # Worker-only nodes
      hosts:
        microk8s-worker-1:
        microk8s-worker-2:
```

**Flexible**: Start with 3 nodes, add workers later without downtime!

---

## Enhanced Roles (Production-Ready)

All roles recently enhanced with **community best practices** from top-rated implementations.

### 1. microk8s_install ✅

**Base MicroK8s installation with production features**

**Features**:
- ✅ Snap installation with version control
- ✅ Kubectl and Helm alias creation
- ✅ User group management for kubectl access
- ✅ CA certificate trust in system store
- ✅ Custom CSR template support
- ✅ Raspberry Pi detection and packages
- ✅ Snap autoupdate disable option

**Key Variables**:
```yaml
microk8s_version: "1.30/stable"
microk8s_users: [ansible, ubuntu]
microk8s_disable_snap_autoupdate: true
microk8s_create_kubectl_alias: true
```

### 2. microk8s_cluster ✅

**HA cluster formation with designated master pattern**

**Features**:
- ✅ **Designated Master Pattern**: First sorted node becomes master
- ✅ **Token-Based Join**: Idempotent cluster formation
- ✅ **Worker Node Support**: Dedicated `--worker` flag
- ✅ **/etc/hosts Management**: Automatic hostname resolution
- ✅ **Cluster Validation**: Ensures all nodes are Ready
- ✅ **Error Handling**: Gracefully handles "already joined" states

**Key Variables**:
```yaml
microk8s_enable_ha: true
microk8s_group_ha: "microk8s"
microk8s_group_workers: "microk8s_workers"
microk8s_join_timeout: 300
microk8s_add_hosts_entries: true
```

**Cluster Formation Logic**:
1. Determines designated master (first in sorted list)
2. Adds /etc/hosts entries for stable networking
3. Master waits for readiness
4. Secondary nodes check membership before joining
5. Workers join with `--worker` flag
6. Final validation ensures cluster health

### 3. microk8s-addons ✅

**30+ addon management with status-based idempotency**

**Features**:
- ✅ **Status Checking**: Only enables/disables if needed
- ✅ **30+ Addons**: Core, Networking, Storage, ML, Service Mesh
- ✅ **Parameter Support**: Boolean and string-parameter addons
- ✅ **Helm Integration**: Automatic repository management

**Key Variables**:
```yaml
microk8s_plugins:
  # Core Addons
  dns: "8.8.8.8,1.1.1.1"
  ingress: true
  metallb: "192.168.4.240-192.168.4.250"
  helm3: true
  dashboard: true

  # Monitoring
  prometheus: false
  observability: false

  # Storage
  openebs: false
  hostpath-storage: true

  # Service Mesh
  istio: false
  linkerd: false
```

**Addon Categories**:
- Core: DNS, Ingress, RBAC, Storage
- Monitoring: Dashboard, Prometheus, Observability
- Networking: MetalLB, Cilium, Traefik
- Service Mesh: Istio, Linkerd
- Storage: OpenEBS, Mayastor, HostPath
- ML/AI: Kubeflow
- Autoscaling: KEDA
- Security: Kata, Cert-Manager

### 4. rancher

**Rancher deployment via Helm on MicroK8s**

**Features**:
- Helm-based installation
- Cert-manager integration
- Bootstrap password management
- Custom hostname configuration

### 5. argocd

**ArgoCD GitOps deployment**

**Features**:
- Manifest-based installation
- Ingress configuration
- Initial admin password retrieval
- LoadBalancer/NodePort options

---

## Configuration Files

### ansible.cfg

- **Inventory**: Uses `production.yml` (static) or `proxmox.yml` (dynamic)
- **SSH**: Optimized with ControlMaster and connection pooling
- **Caching**: JSON fact caching (24h TTL)
- **Output**: YAML callback with diff display
- **Security**: Host key checking disabled for development

### group_vars/all.yml

Global configuration:
```yaml
# Network Configuration
home_network_gateway: "192.168.1.1"
cluster_network_gateway: "192.168.4.1"

# Cluster Nodes
cluster_nodes:
  - name: "microk8s-1"
    ip: "192.168.4.11"
  - name: "microk8s-2"
    ip: "192.168.4.12"
  - name: "microk8s-3"
    ip: "192.168.4.13"

# Service Configuration
rancher_hostname: "rancher.ansible"
argocd_hostname: "argocd.ansible"

# Jumpbox for SSH proxy
jumpbox_ip_home: "192.168.30.240"
```

### Inventory Files

**production.yml** (Primary):
- Static inventory for production cluster
- Defines `microk8s` group for HA nodes
- Optional `microk8s_workers` group for worker nodes

**proxmox.yml** (Dynamic - Optional):
- Proxmox dynamic inventory configuration
- Auto-discovers VMs based on tags/names
- Useful for larger deployments

---

## Playbooks

### Main Playbooks

- **`playbook.yml`**: Complete deployment (MicroK8s + Rancher + ArgoCD)
- **`microk8s-initial-install.yml`**: MicroK8s installation only
- **`add-system-user.yml`**: User management
- **`proxmox-build-template.yml`**: Create Proxmox VM templates
- **`proxmox-create-terraform-user.yml`**: Setup Terraform user on Proxmox
- **`proxmox-enable-vlan-bridging.yml`**: Enable VLAN support

### Example Playbooks (`examples/`)

Pattern demonstrations:
- **`infisical-demo.yml`**: Secret retrieval patterns
- **`connectivity-test-*.yml`**: Network validation
- **`smoke-test-vault.yml`**: Vault integration test

---

## Standards & Patterns

### Idempotency

✅ **All roles are fully idempotent**:
- Status checks before changes
- `changed_when` on all commands
- Graceful error handling for "already exists" states

### Secrets Management

**Infisical Integration** (Primary):
```yaml
- name: Retrieve secret from Infisical
  include_tasks: tasks/infisical-secret-lookup.yml
  vars:
    secret_path: "/path/to/secret"
    secret_key: "SECRET_NAME"
```

**Environment Fallback**:
```yaml
vault_token: "{{ lookup('env', 'VAULT_TOKEN') | default(infisical_token) }}"
```

### Validation & Pre-flight Checks

- Host connectivity verification
- Secret availability checks
- Cluster readiness assertions
- Service health validation

### Tags for Granular Control

```bash
# Install only
ansible-playbook playbooks/playbook.yml --tags install

# Configure only
ansible-playbook playbooks/playbook.yml --tags configure

# Validate only
ansible-playbook playbooks/playbook.yml --tags validate
```

---

## Testing & Validation

### Syntax Check

```bash
# Check main playbook
ansible-playbook --syntax-check playbooks/playbook.yml

# Check all playbooks
find playbooks -name "*.yml" -type f | xargs -I {} ansible-playbook --syntax-check {}
```

### Dry Run

```bash
# Dry run with diff
ansible-playbook --check --diff playbooks/playbook.yml
```

### Linting

```bash
# Lint entire ansible directory
ansible-lint ansible/

# Lint specific roles
ansible-lint ansible/roles/microk8s_install/
```

### YAML Validation

```bash
# Validate YAML syntax
yamllint ansible/roles/*/tasks/main.yml
```

---

## Deployment Workflow

### Initial Deployment (3-Node Cluster)

```bash
# 1. Verify inventory
ansible-inventory --list

# 2. Test connectivity
ansible all -m ping

# 3. Deploy cluster
ansible-playbook playbooks/playbook.yml

# 4. Verify cluster
microk8s kubectl get nodes
```

### Adding Worker Nodes Later

```bash
# 1. Update inventory (add microk8s_workers group)
# 2. Re-run playbook (idempotent - only adds workers)
ansible-playbook playbooks/playbook.yml

# 3. Verify workers joined
microk8s kubectl get nodes
```

---

## Modular Design Benefits

### ✨ Flexibility

- **Start Small**: 3-node HA cluster
- **Scale Up**: Add workers anytime without downtime
- **Mix Workloads**: Control-plane + dedicated workers

### 🎯 Idempotent Operations

- **Safe Re-runs**: Run playbook multiple times safely
- **Incremental Changes**: Only changes what's needed
- **No Duplicates**: Checks state before modifications

### 📦 Reusable Roles

- **Galaxy Standard**: Use in other projects
- **Well Documented**: Each role has comprehensive README
- **Tested**: Production-grade patterns from community

### 🔧 Easy Customization

- **Override Defaults**: Set variables per environment
- **Selective Deployment**: Use tags for granular control
- **Addon Flexibility**: Enable/disable 30+ addons easily

---

## Environment Setup

### Required Environment Variables

```bash
# Infisical authentication (retrieves all secrets)
export INFISICAL_UNIVERSAL_AUTH_CLIENT_ID="..."
export INFISICAL_UNIVERSAL_AUTH_CLIENT_SECRET="..."
```

All infrastructure secrets (Proxmox credentials, service tokens, etc.) are retrieved from Infisical at runtime.

### Optional Environment Variables

```bash
# Override specific secrets if needed
export VAULT_TOKEN="..."
export CONSUL_HTTP_TOKEN="..."
export NOMAD_TOKEN="..."
```

---

## Troubleshooting

### Common Issues

**Issue**: Cluster formation fails
```bash
# Check designated master is Ready
microk8s status --wait-ready

# Verify network connectivity
ansible all -m ping

# Check logs
journalctl -u snap.microk8s.daemon-kubelite
```

**Issue**: Addons not enabling
```bash
# Check addon status
microk8s status

# Manually enable for testing
microk8s enable dns ingress
```

**Issue**: Workers not joining
```bash
# Verify microk8s_workers group in inventory
ansible-inventory --list | jq '.microk8s_workers'

# Check join token generation
microk8s add-node
```

---

## Advanced Patterns

### Custom Certificates

```yaml
# defaults/main.yml
microk8s_csr_template: "templates/custom-csr.conf.j2"
```

### Addon Dependencies

Some addons have dependencies (managed automatically):
- `dashboard` requires `metrics-server`
- `rancher` requires `helm3`
- `metallb` requires cluster CIDR configuration

### Multiple Environments

```bash
# Production
ansible-playbook -i inventory/production.yml playbooks/playbook.yml

# Staging (if you have it)
ansible-playbook -i inventory/staging.yml playbooks/playbook.yml
```

---

## Documentation References

- **[Ansible Standards](../docs/standards/ansible-standards.md)**: Detailed patterns and best practices
- **[MicroK8s Implementation](../docs/ansible/microk8s-implementation-enhancements.md)**: Enhancement details
- **[Role READMEs](roles/)**: Individual role documentation

---

## Contributing

When adding new roles or playbooks:

1. Follow Galaxy role structure (`defaults/`, `handlers/`, `tasks/`, etc.)
2. Ensure idempotency (use `changed_when` appropriately)
3. Add comprehensive defaults with comments
4. Include role README with usage examples
5. Test with `ansible-lint` and `--syntax-check`

---

## Quality Assurance

✅ **Ansible-Lint**: Production profile passed
✅ **Syntax Checks**: All playbooks valid
✅ **YAML Lint**: All roles syntactically correct
✅ **Idempotency**: Fully tested and verified
✅ **Best Practices**: Community patterns adopted

**Status**: Production-Ready 🚀

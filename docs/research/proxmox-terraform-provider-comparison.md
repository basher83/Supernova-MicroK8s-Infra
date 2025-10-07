# Proxmox Terraform Provider Comparison & Research

**Research Date:** January 5, 2025
**Objective:** Evaluate and compare Proxmox Terraform providers to identify the optimal solution for infrastructure automation

---

## Executive Summary

This research analyzes the three most prominent Terraform providers for Proxmox Virtual Environment, with a focus on download statistics, active development, feature sets, and production readiness. Based on comprehensive analysis:

**Recommendation:** **bpg/proxmox** is the clear leader and recommended choice for all use cases in 2025.

### Quick Comparison Matrix

| Metric | bpg/proxmox | Telmate/proxmox | TheGameProfi/proxmox |
|--------|-------------|-----------------|----------------------|
| **Status** | ✅ Active | ⚠️ Limited Maintenance | ❌ Deprecated |
| **Total Downloads** | 9.86M+ | N/A | N/A |
| **Weekly Downloads** | 13.6k | N/A | N/A |
| **GitHub Stars** | 1.5k | 2.7k | N/A |
| **Contributors** | 119 | 150 | N/A |
| **Latest Version** | 0.84.1 | 3.0.2-rc04 | 2.10.0 (archived) |
| **Last Release** | Sept 29, 2025 | Aug 23, 2025 | Deprecated |
| **Proxmox 9.x Support** | ✅ Full | ⚠️ Limited | ❌ No |
| **Proxmox 8.x Support** | ✅ Yes | ✅ Yes | ❌ No |
| **Resource Count** | 40+ resources | 2 resources | 2 resources |
| **License** | MPL-2.0 | MIT | MIT |
| **Production Ready** | ✅ Yes | ⚠️ Limited | ❌ No |

---

## Provider Profiles

### 1. bpg/proxmox (RECOMMENDED)

**Registry:** `registry.terraform.io/providers/bpg/proxmox`
**Repository:** [github.com/bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox)
**Version:** 0.84.1 (Sept 2025)

#### Download Statistics

- **Total Downloads:** 9.86 million
- **Weekly:** 13.6k downloads
- **Monthly:** 66.4k downloads
- **Annual:** 5.57 million downloads (2025)
- **Growth Trajectory:** Rapidly increasing adoption

#### Community Metrics

- **GitHub Stars:** 1,470+
- **Forks:** 211
- **Contributors:** 119 (highly collaborative)
- **Releases:** 146 versions
- **Activity:** 30+ releases in last year
- **Issues Response:** Fast response time on bug reports

#### Strengths

1. **Comprehensive Feature Set**
   - 40+ Terraform resources
   - Full cluster management
   - Software Defined Networking (SDN) support
   - High Availability (HA) resource management
   - User and permission management
   - ACL and security group management
   - Storage/datastore configuration
   - Network configuration (including VLAN awareness)
   - Hardware mapping support
   - Cloud-init integration

2. **Active Development**
   - Regular feature additions
   - Rapid bug fixes
   - Community-driven improvements
   - Migration to Terraform Plugin Framework underway (v1.0 planned)
   - Excellent documentation with detailed guides

3. **Advanced Capabilities**
   - Direct download of cloud images to Proxmox nodes
   - VM template building from cloud images
   - SSH integration for complex operations
   - SOCKS5 proxy support
   - Multiple authentication methods (API token, password, pre-auth tickets)
   - Per-node IP address configuration for SSH
   - Random VM ID generation to avoid conflicts

4. **Production Features**
   - Comprehensive error handling
   - Idempotent operations
   - State management
   - Import existing resources
   - Detailed logging and debugging capabilities
   - TLS 1.3 support with optional 1.2 fallback

5. **Enterprise Capabilities**
   - Cluster-wide operations
   - Multi-node deployments
   - HA resource management (Proxmox 8.x - 9.0 API changes pending)
   - PCI passthrough configuration
   - USB port mapping
   - Backup management

#### Weaknesses

1. **Version Stability**
   - Still on 0.x version (pre-1.0)
   - Breaking changes possible between minor versions (though minimized)
   - Framework migration in progress

2. **Proxmox 9.0 Limitations**
   - New HA API not yet fully supported
   - `apt_*` resources don't support deb822 format

3. **Complexity**
   - Steeper learning curve due to extensive features
   - More configuration options to understand
   - SSH setup required for some operations

4. **Authentication Requirements**
   - PAM account required for snippet uploads
   - Root PAM account required for hardware mappings
   - SSH username needed when using API tokens

5. **Known Issues**
   - Serial device required for Debian 12/Ubuntu VMs
   - VMware disk images need workaround
   - HA VM drift detection issues
   - Lock errors possible with parallel VM creation

#### Unique Capabilities

- **Direct cloud image downloads:** Download ISO and disk images directly to Proxmox nodes without local buffering
- **Comprehensive SDN:** Full software-defined networking with VNET and subnet resources
- **Hardware mapping:** PCI passthrough and USB port mapping for advanced configurations
- **Multi-authentication:** Supports API tokens, passwords, and pre-authenticated tickets
- **Per-node SSH:** Configure different IP addresses for SSH per node in cluster
- **Random VM IDs:** Automatic conflict avoidance with random ID generation

---

### 2. Telmate/proxmox (LEGACY)

**Registry:** `registry.terraform.io/providers/Telmate/proxmox`
**Repository:** [github.com/Telmate/terraform-provider-proxmox](https://github.com/Telmate/terraform-provider-proxmox)
**Version:** 3.0.2-rc04 (Aug 2025)

#### Community Metrics

- **GitHub Stars:** 2,700
- **Forks:** 584
- **Contributors:** 150
- **Years Active:** 9 years (since 2017)
- **Status:** Limited maintenance mode

#### Strengths

1. **Maturity**
   - Established provider with 9-year history
   - Large existing user base
   - Extensive community knowledge/tutorials

2. **Simplicity**
   - Easy to understand for basic use cases
   - Straightforward configuration
   - Less complex than bpg for simple deployments

3. **Basic Functionality**
   - QEMU VM provisioning (`proxmox_vm_qemu`)
   - LXC container management (`proxmox_lxc`)
   - Cloud-init disk support
   - Pool management

4. **Documentation**
   - Extensive community tutorials
   - Many blog posts and guides available
   - Well-documented basic features

#### Weaknesses

1. **Limited Feature Set**
   - **Only 2 primary resources** (vm_qemu, lxc)
   - Cannot manage:
     - Cluster configuration
     - Network settings
     - SDN
     - Users/permissions
     - Security groups
     - ACLs
     - Storage configuration
     - HA resources

2. **Known Bugs**
   - Disk size attribute doesn't match Proxmox UI
   - Updates frequently show as failed in Proxmox UI (cosmetic but confusing)
   - LXC resource crashes if `rootfs` not defined
   - PXE boot requires specific NIC configuration workaround

3. **Version Issues**
   - v2.9 incompatible with Proxmox 8.x
   - v3.0 still in RC (release candidate) phase
   - Breaking changes between major versions

4. **Development Status**
   - Limited new feature development
   - Maintenance mode
   - Slower response to issues
   - Focus on stability over innovation

5. **Scalability**
   - Not suitable for complex Proxmox environments
   - Cannot manage enterprise features
   - Limited to basic VM/container operations

#### Use Cases

- **Simple home labs** with basic VM/LXC needs
- **Single-node** Proxmox deployments
- **Migration legacy** - Existing deployments already using Telmate
- **Learning Terraform** - Simpler for beginners

---

### 3. TheGameProfi/proxmox (DEPRECATED)

**Status:** ❌ **DEPRECATED - DO NOT USE**

**Registry:** `registry.terraform.io/providers/TheGameProfi/proxmox`
**Repository:** [github.com/TheGameProfi/terraform-provider-proxmox](https://github.com/TheGameProfi/terraform-provider-proxmox)
**Version:** 2.10.0 (archived)

#### Background

TheGameProfi/proxmox was a community fork of Telmate/proxmox created when the original Telmate provider appeared unmaintained. It included bug fixes and community contributions.

#### Current Status

- **Officially deprecated** as of 2024
- Original Telmate provider resumed maintenance
- All fixes merged back to Telmate
- Users instructed to migrate to Telmate or bpg

#### Migration Path

```hcl
# Old (deprecated)
terraform {
  required_providers {
    proxmox = {
      source = "TheGameProfi/proxmox"
    }
  }
}

# New (recommended)
terraform {
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
    }
  }
}
```

---

## Detailed Comparison

### Feature Comparison

#### Resource Coverage

| Feature Category | bpg/proxmox | Telmate/proxmox |
|------------------|-------------|-----------------|
| **Virtual Machines** | ✅ Full (`virtual_environment_vm`) | ✅ Basic (`vm_qemu`) |
| **LXC Containers** | ✅ Full | ✅ Basic (`lxc`) |
| **Cluster Management** | ✅ Yes | ❌ No |
| **User Management** | ✅ Yes (`virtual_environment_user`) | ❌ No |
| **Role Management** | ✅ Yes (`virtual_environment_role`) | ❌ No |
| **ACLs** | ✅ Yes | ❌ No |
| **Groups** | ✅ Yes | ❌ No |
| **Pools** | ✅ Yes | ✅ Yes (`pool`) |
| **Storage/Datastores** | ✅ Yes | ❌ No |
| **Network Config** | ✅ Yes | ❌ No |
| **SDN** | ✅ Full (VNet, Subnet, Zones) | ❌ No |
| **HA Resources** | ✅ Yes (8.x, 9.0 pending) | ❌ No |
| **File Management** | ✅ Yes (upload, download) | ❌ No |
| **DNS** | ✅ Yes | ❌ No |
| **Time/NTP** | ✅ Yes | ❌ No |
| **Certificates** | ✅ Yes | ❌ No |
| **Firewall** | ✅ Yes | ❌ No |
| **Hardware Mapping** | ✅ Yes (PCI, USB) | ❌ No |
| **Backup** | ✅ Yes | ❌ No |
| **Cloud-Init** | ✅ Advanced | ✅ Basic |

#### Data Sources

| Data Source | bpg/proxmox | Telmate/proxmox |
|-------------|-------------|-----------------|
| **VMs** | ✅ Yes | ❌ No |
| **Nodes** | ✅ Yes | ❌ No |
| **Pools** | ✅ Yes | ❌ No |
| **Datastores** | ✅ Yes | ❌ No |
| **Network Interfaces** | ✅ Yes | ❌ No |
| **DNS** | ✅ Yes | ❌ No |
| **Time** | ✅ Yes | ❌ No |
| **Version** | ✅ Yes | ❌ No |
| **Hosts** | ✅ Yes | ❌ No |

### Authentication Comparison

#### bpg/proxmox

**Methods Supported:**
1. **API Token** (recommended for production)
   - Fine-grained permissions
   - Revocable
   - No password needed
   - Some operations require PAM fallback

2. **Username/Password**
   - Full API support
   - Simpler setup
   - Not individually revocable

3. **Pre-authenticated Ticket**
   - Short-lived tokens
   - TOTP support
   - Complex setup
   - Requires renewal

**SSH Integration:**
- SSH agent support
- Private key authentication
- Per-node address configuration
- SOCKS5 proxy support
- Required for snippets and some operations

#### Telmate/proxmox

**Methods Supported:**
1. **Username/Password**
2. **API Token**
3. **OTP** (deprecated)

**Simpler:** No SSH configuration required for basic operations

### Network Features

#### bpg/proxmox

- Full SDN support (VNet, Subnet, Zones)
- VLAN configuration
- Bridge management
- Linux Bridge
- OVS (Open vSwitch)
- Bond configuration
- VLAN-aware bridges
- IPv4 and IPv6
- Gateway configuration
- MTU settings
- Network interface hotplug

#### Telmate/proxmox

- Basic NIC configuration
- VLAN tags (basic)
- Bridge selection
- Limited network options

### Storage/Disk Features

#### bpg/proxmox

- Multiple disk interfaces (SCSI, SATA, VirtIO, IDE)
- Disk import from URLs
- Disk resizing
- Disk migration
- SSD emulation
- Discard/TRIM support
- I/O thread configuration
- Cache modes
- AIO modes
- Backup configuration per disk
- Multiple storage types
- Cloud image downloads
- Template creation

#### Telmate/proxmox

- Basic disk configuration
- Size specification (with UI mismatch bug)
- Storage selection
- Limited disk types
- Basic cloud-init disk

---

## Use Case Recommendations

### When to Use bpg/proxmox ✅

1. **Production Environments**
   - Enterprise deployments
   - Multi-node clusters
   - HA requirements
   - Complex networking (SDN, VLANs)
   - Compliance/audit requirements

2. **Advanced Features**
   - Hardware passthrough (PCI, USB)
   - Software-defined networking
   - Multi-tenant environments
   - User/permission management automation
   - Firewall rules automation

3. **Scale**
   - Large VM/container counts
   - Multiple Proxmox clusters
   - Automated template management
   - Cloud-init customization

4. **Modern Infrastructure**
   - Proxmox 9.x deployments
   - New projects starting in 2025
   - GitOps workflows
   - CI/CD integration

5. **Full Infrastructure as Code**
   - Everything in Terraform
   - No manual Proxmox configuration
   - Cluster-wide automation
   - Complete state management

### When to Use Telmate/proxmox ⚠️

1. **Legacy Deployments**
   - Existing Telmate configurations
   - Migration not yet feasible
   - No immediate need for advanced features

2. **Simple Use Cases**
   - Single-node home labs
   - Basic VM provisioning only
   - No cluster management needed
   - No SDN requirements

3. **Learning/Testing**
   - Terraform beginners
   - Simple proof-of-concept
   - Minimal configuration complexity

4. **Constraints**
   - Cannot use SSH (bpg requirement for some features)
   - Only need basic VM/LXC creation

**⚠️ Migration Recommended:** Even for simple use cases, consider migrating to bpg/proxmox for:
- Future feature needs
- Better support
- Active development
- Bug fixes

---

## Migration Strategy

### Telmate → bpg Migration

#### Step 1: Assessment

```bash
# List current resources
terraform state list | grep proxmox
```

#### Step 2: Parallel Installation

```hcl
terraform {
  required_providers {
    proxmox-old = {
      source  = "Telmate/proxmox"
      version = "~> 3.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.84"
    }
  }
}
```

#### Step 3: Resource Mapping

```hcl
# Telmate
resource "proxmox_vm_qemu" "example" {
  name        = "vm-example"
  target_node = "pve"
  # ...
}

# bpg equivalent
resource "proxmox_virtual_environment_vm" "example" {
  name      = "vm-example"
  node_name = "pve"
  # ...
}
```

#### Step 4: State Migration

```bash
# Export current state
terraform state pull > backup.tfstate

# Import to new provider
terraform import proxmox_virtual_environment_vm.example <vm_id>

# Remove old resource
terraform state rm proxmox_vm_qemu.example
```

#### Key Differences

| Telmate | bpg |
|---------|-----|
| `target_node` | `node_name` |
| `disk { }` | `disk { datastore_id, file_id, ... }` |
| `network { }` | `network_device { }` |
| `clone` | `clone { }` block with more options |
| Limited cloud-init | Advanced `initialization { }` block |

---

## Technical Deep Dive

### Architecture Comparison

#### bpg/proxmox

**Framework:** Migrating from Terraform SDKv2 → Plugin Framework
- Modern architecture
- Better type safety
- Improved validation
- Enhanced error messages
- Plugin protocol 6 support (future)

**API Integration:**
- Direct Proxmox API calls
- SSH integration for advanced operations
- SFTP for file uploads
- WebSocket support (planned)

**State Management:**
- Comprehensive resource tracking
- Import support for all resources
- Drift detection
- Refresh capabilities

#### Telmate/proxmox

**Framework:** Terraform SDKv2 (legacy)
- Maintenance mode framework
- Basic type validation
- Limited error handling

**API Integration:**
- Proxmox API only
- No SSH requirement
- Limited operation support

**State Management:**
- Basic resource tracking
- Limited import support
- Some drift detection issues

### Performance Comparison

| Metric | bpg/proxmox | Telmate/proxmox |
|--------|-------------|-----------------|
| **VM Creation Speed** | Faster (direct downloads) | Standard |
| **Parallel Operations** | Configurable (issues with locks) | Limited parallelism |
| **API Calls** | Optimized | Standard |
| **Template Creation** | Native support | Manual process |
| **Cloud Image Handling** | Direct to node | Local → upload |

### Security Comparison

#### bpg/proxmox

**Authentication:**
- API tokens with privilege separation
- TLS 1.3 (optionally 1.2)
- SSH key authentication
- SSH agent support
- SOCKS5 proxy support

**Authorization:**
- Fine-grained permissions via roles
- Per-resource ACLs
- Audit logging support

**Secrets Management:**
- Environment variables
- Terraform variables
- External secret stores (via data sources)

#### Telmate/proxmox

**Authentication:**
- Username/password
- Basic API token
- TLS support

**Authorization:**
- Proxmox user permissions

**Secrets Management:**
- Environment variables
- Terraform variables

---

## Compatibility Matrix

### Proxmox Version Support

| Proxmox Version | bpg/proxmox | Telmate/proxmox |
|-----------------|-------------|-----------------|
| **9.0** | ✅ Full support (some HA API pending) | ⚠️ Limited testing |
| **8.x** | ✅ Full support | ✅ Yes (v3.0+) |
| **7.x** | ❌ Not tested/supported | ⚠️ May work (v2.9) |
| **< 7.0** | ❌ No | ⚠️ Legacy versions only |

### Terraform/OpenTofu Support

| Tool | Version | bpg/proxmox | Telmate/proxmox |
|------|---------|-------------|-----------------|
| **Terraform** | 1.5+ | ✅ Yes | ✅ Yes |
| **Terraform** | 1.0-1.4 | ⚠️ May work | ✅ Yes |
| **Terraform** | < 1.0 | ❌ No | ⚠️ Legacy only |
| **OpenTofu** | 1.6+ | ✅ Yes | ✅ Yes |
| **OpenTofu** | < 1.6 | ⚠️ May work | ⚠️ May work |

---

## Real-World Examples

### Simple VM Creation

#### bpg/proxmox

```hcl
resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "ubuntu-vm"
  node_name = "pve"

  agent {
    enabled = true
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(tls_private_key.ubuntu_vm_key.public_key_openssh)]
    }
  }

  network_device {
    bridge = "vmbr0"
  }
}
```

#### Telmate/proxmox

```hcl
resource "proxmox_vm_qemu" "ubuntu_vm" {
  name        = "ubuntu-vm"
  target_node = "pve"
  cores       = 2
  memory      = 2048

  disk {
    size    = "20G"
    type    = "virtio"
    storage = "local-lvm"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  os_type = "cloud-init"
  ipconfig0 = "ip=dhcp"
  sshkeys = tls_private_key.ubuntu_vm_key.public_key_openssh
}
```

### Advanced: Cluster with SDN

#### bpg/proxmox (Fully Supported)

```hcl
# Create SDN Zone
resource "proxmox_virtual_environment_sdn_zone" "vlan_zone" {
  zone = "vlan-zone"
  type = "vlan"

  nodes = ["pve1", "pve2", "pve3"]
  bridge = "vmbr0"
}

# Create VNET
resource "proxmox_virtual_environment_sdn_vnet" "management" {
  zone  = proxmox_virtual_environment_sdn_zone.vlan_zone.zone
  vnet  = "mgmt-vnet"
  alias = "Management Network"
  vlanaware = true
}

# Create Subnet
resource "proxmox_virtual_environment_sdn_subnet" "mgmt_subnet" {
  vnet    = proxmox_virtual_environment_sdn_vnet.management.vnet
  subnet  = "10.0.10.0/24"
  gateway = "10.0.10.1"
  dns     = "10.0.10.2"
}

# VM using SDN
resource "proxmox_virtual_environment_vm" "sdn_vm" {
  name      = "sdn-vm"
  node_name = "pve1"
  # ... other config ...

  network_device {
    bridge  = proxmox_virtual_environment_sdn_vnet.management.vnet
    vlan_id = 50
  }
}
```

#### Telmate/proxmox

```hcl
# NOT SUPPORTED - Manual Proxmox configuration required
```

---

## Cost-Benefit Analysis

### Development Time

| Task | bpg/proxmox | Telmate/proxmox |
|------|-------------|-----------------|
| **Initial Setup** | 2-4 hours | 1-2 hours |
| **Simple VM** | 30 minutes | 30 minutes |
| **Complex VM** | 1 hour | 2-4 hours (manual steps) |
| **Cluster Setup** | 4-8 hours | Not possible (manual) |
| **SDN Configuration** | 2-3 hours | Not possible (manual) |
| **User Management** | 1 hour | Not possible (manual) |

### Maintenance Overhead

| Aspect | bpg/proxmox | Telmate/proxmox |
|--------|-------------|-----------------|
| **Version Updates** | Frequent, well-documented | Infrequent, potential breaking changes |
| **Bug Fixes** | Fast response | Slower response |
| **Feature Requests** | Active community | Limited development |
| **Documentation** | Excellent, up-to-date | Good, community-driven |
| **Breaking Changes** | Minimized, documented | Higher risk between major versions |

### Long-Term Value

**bpg/proxmox:**
- ✅ Future-proof (active development)
- ✅ Growing feature set
- ✅ Community support
- ✅ Enterprise-ready
- ✅ Reduces manual configuration
- ✅ Complete IaC coverage

**Telmate/proxmox:**
- ⚠️ Maintenance mode
- ⚠️ Limited features
- ⚠️ Requires manual Proxmox configuration for advanced features
- ⚠️ May become obsolete
- ✅ Stable for basic use cases
- ⚠️ Partial IaC coverage

---

## Decision Matrix

### Scoring (1-10 scale)

| Criteria | Weight | bpg/proxmox | Telmate/proxmox |
|----------|--------|-------------|-----------------|
| **Feature Completeness** | 25% | 10 | 3 |
| **Active Development** | 20% | 10 | 4 |
| **Community Support** | 15% | 9 | 7 |
| **Documentation** | 10% | 9 | 7 |
| **Stability** | 15% | 8 | 6 |
| **Ease of Use** | 10% | 7 | 9 |
| **Enterprise Features** | 5% | 10 | 2 |
| ****Total (Weighted)** | **100%** | **9.15** | **5.25** |

---

## Answers to Key Questions

### What are the major differences between the providers?

**Resource Coverage:**
- **bpg/proxmox:** 40+ resources covering complete Proxmox infrastructure
- **Telmate/proxmox:** 2 primary resources (VMs and LXC containers only)

**Scope:**
- **bpg:** Complete infrastructure automation (cluster, network, users, storage, VMs)
- **Telmate:** VM and container provisioning only

**Development:**
- **bpg:** Active development, 30+ releases/year, rapid bug fixes
- **Telmate:** Maintenance mode, infrequent updates

**Architecture:**
- **bpg:** Migrating to modern Plugin Framework
- **Telmate:** Legacy SDKv2 framework

### What are the particular strengths and weaknesses of each provider?

#### bpg/proxmox Strengths

1. **Comprehensive:** Manages every aspect of Proxmox
2. **Modern:** Active development with latest features
3. **Enterprise:** HA, SDN, clustering, permissions
4. **Performance:** Direct cloud image downloads, optimized operations
5. **Future-proof:** Plugin Framework migration, continuous improvement

#### bpg/proxmox Weaknesses

1. **Complexity:** Steeper learning curve
2. **Pre-1.0:** Potential breaking changes (though minimized)
3. **SSH Required:** Some operations need SSH setup
4. **Proxmox 9.0:** Some new APIs not yet supported

#### Telmate/proxmox Strengths

1. **Simplicity:** Easy to understand
2. **Established:** 9-year track record
3. **Community:** Large existing user base with tutorials
4. **No SSH:** Simpler authentication setup

#### Telmate/proxmox Weaknesses

1. **Limited:** Only VM/LXC creation
2. **Bugs:** Known issues with disk size, UI errors
3. **Maintenance Mode:** Slow feature development
4. **Incomplete:** Requires manual Proxmox configuration for advanced features

### What are the reasons to use provider X over provider Y?

**Use bpg/proxmox when:**
- ✅ You need complete infrastructure automation
- ✅ Managing multi-node clusters
- ✅ Require SDN, HA, or advanced networking
- ✅ Want enterprise features (permissions, ACLs, hardware mapping)
- ✅ Starting new projects in 2025
- ✅ Need active support and frequent updates
- ✅ Want to avoid manual Proxmox configuration
- ✅ Proxmox 9.x environment

**Use Telmate/proxmox when:**
- ⚠️ Maintaining legacy deployments
- ⚠️ Only need basic VM/LXC creation
- ⚠️ Cannot use SSH
- ⚠️ Extreme simplicity required
- ⚠️ Migration not yet feasible

**Avoid TheGameProfi/proxmox:**
- ❌ Deprecated, migrate immediately to bpg or Telmate

### What unique capabilities does provider X have over provider Y?

#### bpg/proxmox UNIQUE to bpg

1. **Software Defined Networking (SDN)**
   - VNet creation
   - Subnet management
   - Zone configuration
   - VLAN-aware bridges

2. **Cluster Management**
   - Multi-node coordination
   - Cluster options
   - Cluster firewall

3. **User & Permission Management**
   - User creation/management
   - Role definition
   - ACL configuration
   - Group management

4. **Storage Management**
   - Datastore configuration
   - Storage types
   - Content types

5. **Hardware Features**
   - PCI passthrough mapping
   - USB port mapping
   - Hardware resource pools

6. **High Availability**
   - HA resource configuration (Proxmox 8.x)
   - HA groups

7. **Advanced Networking**
   - Network interface management
   - Bond configuration
   - Bridge creation
   - VLAN configuration

8. **File Management**
   - Direct cloud image downloads to nodes
   - Snippet uploads
   - Backup management

9. **Security**
   - Firewall rules
   - Security groups
   - Certificate management

10. **Monitoring & Operational**
    - Time/NTP configuration
    - DNS settings
    - Apt repository management

#### Telmate/proxmox UNIQUE to Telmate

**None.** All Telmate capabilities are available in bpg/proxmox with enhanced features.

---

## Conclusion

### Final Recommendation

**Primary:** **bpg/proxmox** for all new deployments and production environments

**Rationale:**
1. **Comprehensive feature coverage** - Manages complete Proxmox infrastructure
2. **Active development** - 30+ releases per year, fast bug fixes
3. **Future-proof** - Migration to modern framework, continuous improvement
4. **Enterprise-ready** - HA, SDN, clustering, permissions, security
5. **Growing adoption** - 9.86M+ downloads, rapidly increasing
6. **Excellent documentation** - Detailed guides and examples
7. **Community support** - Responsive maintainers, 119 contributors

### Migration Timeline

**Immediate (Q1 2025):**
- New projects: Start with bpg/proxmox
- Proxmox 9.x deployments: Use bpg/proxmox

**Short-term (Q2 2025):**
- Existing Telmate users: Evaluate migration if advanced features needed
- Plan migration for cluster/SDN/HA requirements

**Long-term (2025-2026):**
- All Telmate users: Plan migration to bpg/proxmox
- TheGameProfi users: Migrate immediately to bpg/proxmox

### Risk Assessment

**Using bpg/proxmox:**
- **Risk Level:** Low
- **Mitigation:** Active community, frequent releases, good documentation

**Using Telmate/proxmox:**
- **Risk Level:** Medium
- **Concerns:** Maintenance mode, limited features, potential obsolescence
- **Mitigation:** Plan migration path to bpg/proxmox

**Using TheGameProfi/proxmox:**
- **Risk Level:** High
- **Action:** Immediate migration required

---

## Resources & Links

### bpg/proxmox

- **Terraform Registry:** [registry.terraform.io/providers/bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest)
- **OpenTofu Registry:** [search.opentofu.org/provider/bpg/proxmox](https://search.opentofu.org/provider/bpg/proxmox/latest)
- **GitHub:** [github.com/bpg/terraform-provider-proxmox](https://github.com/bpg/terraform-provider-proxmox)
- **Documentation:** [registry.terraform.io/providers/bpg/proxmox/latest/docs](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)
- **Examples:** [github.com/bpg/terraform-provider-proxmox/tree/main/examples](https://github.com/bpg/terraform-provider-proxmox/tree/main/examples)

### Telmate/proxmox

- **Terraform Registry:** [registry.terraform.io/providers/Telmate/proxmox](https://registry.terraform.io/providers/Telmate/proxmox/latest)
- **GitHub:** [github.com/Telmate/terraform-provider-proxmox](https://github.com/Telmate/terraform-provider-proxmox)
- **Documentation:** [registry.terraform.io/providers/Telmate/proxmox/latest/docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

### Community Resources

- **Proxmox Forum:** [forum.proxmox.com/threads/best-terraform-provider.116152](https://forum.proxmox.com/threads/best-terraform-provider.116152/)
- **Comparison Articles:** Various community blogs and tutorials

---

## Document Metadata

- **Author:** Infrastructure Research Team
- **Date:** January 5, 2025
- **Version:** 1.0
- **Next Review:** April 2025
- **Related Documents:**
  - `docs/troubleshooting/networking-vlan.md` - VLAN configuration guide
  - `terraform/README.md` - Current Terraform implementation

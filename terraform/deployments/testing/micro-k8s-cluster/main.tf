# =============================================================================
# = MicroK8s Cluster Deployment Example ======================================
# =============================================================================
# This example demonstrates deploying a 3-node MicroK8s cluster using the
# vm-cluster module. The cluster consists of identical nodes optimized for
# Kubernetes workloads.

# =============================================================================
# = Local Variables ===========================================================
# =============================================================================

locals {
  network_interfaces = merge(
    {
      net0 = {
        bridge     = var.network_bridge
        vlan_id    = var.vlan_id
        firewall   = false
        model      = "virtio"
        mtu        = 1500
        rate_limit = null
      }
    },
    var.enable_secondary_nic ? {
      net1 = {
        bridge     = var.network_bridge_secondary
        vlan_id    = var.vlan_id_secondary
        firewall   = false
        model      = "virtio"
        mtu        = 1500
        rate_limit = null
      }
    } : {}
  )
}

# =============================================================================
# = MicroK8s Cluster ==========================================================
# =============================================================================

module "microk8s_cluster" {
  source = "../../../modules/vm-cluster"

  # Template configuration
  template_id        = var.template_id
  template_datastore = var.datastore
  template_node      = var.template_node

  # Cluster-wide tags
  cluster_tags = ["microk8s", "kubernetes", "cluster"]

  # Node definitions
  nodes = {
    "microk8s-1-test" = {
      pve_node             = "holly"
      ip_address           = "192.168.10.101"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.101" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-2-test" = {
      pve_node             = "mable"
      ip_address           = "192.168.10.102"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.102" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-3-test" = {
      pve_node             = "lloyd"
      ip_address           = "192.168.10.103"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.103" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
  }

  # Network configuration - Dual NIC setup (conditionally add net1)
  network_interfaces = local.network_interfaces
  network_cidr       = var.network_cidr
  network_gateway    = var.network_gateway

  # Cloud-init configuration
  cloud_init_config = {
    datastore_id = "local"
    interface    = "ide0"
    dns = {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    user = {
      name = "ansible"
      keys = var.ssh_public_keys
    }
  }

  # Start configuration
  start_on_deploy = true
  start_on_boot   = true
}

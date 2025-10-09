# =============================================================================
# = MicroK8s Cluster Deployment Example ======================================
# =============================================================================
# This example demonstrates deploying a 3-node MicroK8s cluster using the
# vm-cluster module. The cluster consists of identical nodes optimized for
# Kubernetes workloads.

# =============================================================================
# = MicroK8s Cluster ==========================================================
# =============================================================================

module "microk8s_cluster" {
  source = "../../../modules/vm-cluster"

  # Template configuration (template lives on source node, VMs deployed to target nodes)
  template_id        = var.template_id
  template_datastore = var.datastore
  template_node      = var.template_node

  # Cluster-wide tags
  cluster_tags = ["microk8s", "kubernetes", "cluster"]

  # Node definitions (cross-node deployment: clone from lloyd, deploy to different nodes)
  nodes = {
    "microk8s-1" = {
      pve_node             = "holly" # Deploy to holly
      ip_address           = "192.168.30.101"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.2.101" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-2" = {
      pve_node             = "mable" # Deploy to mable
      ip_address           = "192.168.30.102"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.2.102" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-3" = {
      pve_node             = "lloyd" # Deploy to lloyd (template host)
      ip_address           = "192.168.30.103"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.2.103" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
  }

  # Network configuration - Dual NIC setup (conditionally add net1)
  network_interfaces = merge(
    {
      net0 = {
        bridge  = var.network_bridge
        vlan_id = var.vlan_id
      }
    },
    var.enable_secondary_nic ? {
      net1 = {
        bridge  = var.network_bridge_secondary
        vlan_id = var.vlan_id_secondary
      }
    } : {}
  )
  network_cidr    = var.network_cidr
  network_gateway = var.network_gateway

  # Cloud-init configuration
  cloud_init_config = {
    datastore_id = "local"
    interface    = "ide0"
    dns = {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
    user = {
      name = "ubuntu"
      keys = var.ssh_public_keys
    }
  }

  # Start configuration
  start_on_deploy = true
  start_on_boot   = true
}

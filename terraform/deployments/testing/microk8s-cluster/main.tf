# =============================================================================
# = MicroK8s Cluster Deployment Example ======================================
# =============================================================================
# This example demonstrates deploying a 3-node MicroK8s cluster using the
# vm module with for_each. This pattern eliminates the need for a separate
# cluster module by using Terraform's native for_each capability.

# =============================================================================
# = Local Values ==============================================================
# =============================================================================

locals {
  # Define cluster nodes with their configuration
  nodes = {
    "microk8s-1" = {
      pve_node             = "holly"
      ip_address           = "192.168.10.101"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.101" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-2" = {
      pve_node             = "mable"
      ip_address           = "192.168.10.102"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.102" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
    "microk8s-3" = {
      pve_node             = "lloyd"
      ip_address           = "192.168.10.103"
      ip_address_secondary = var.enable_secondary_nic ? "192.168.4.103" : null
      cpu_cores            = 4
      memory               = 8192
      disk_size            = 50
    }
  }

  # Cluster-wide tags applied to all nodes
  cluster_tags = ["microk8s", "kubernetes", "cluster"]
}

# =============================================================================
# = MicroK8s Cluster VMs ======================================================
# =============================================================================

module "cluster_vms" {
  source   = "../../../modules/vm"
  for_each = local.nodes

  # Node identification
  vm_type  = "clone"
  pve_node = each.value.pve_node
  vm_name  = each.key
  vm_tags  = concat(local.cluster_tags, ["node-${each.key}"])

  # Clone configuration (always uses template-clone approach for clusters)
  src_clone = {
    datastore_id = var.datastore
    node_name    = var.template_node
    tpl_id       = var.template_id
  }



  # EFI disk for UEFI boot
  vm_efi_disk = {
    datastore_id      = var.datastore
    file_format       = "raw"
    type              = "4m"
    pre_enrolled_keys = false
  }

  # Disk configuration
  vm_disk = {
    scsi0 = {
      datastore_id = var.datastore
      size         = each.value.disk_size
      file_format  = "raw"
      iothread     = true
      ssd          = true
      discard      = "on"
      main_disk    = true
    }
  }

  # Network configuration - Dual NIC setup (conditionally add net1)
  vm_net_ifaces = merge(
    {
      net0 = {
        bridge    = var.network_bridge
        vlan_id   = var.vlan_id
        ipv4_addr = "${each.value.ip_address}/${var.network_cidr}"
        ipv4_gw   = var.network_gateway
      }
    },
    var.enable_secondary_nic && each.value.ip_address_secondary != null ? {
      net1 = {
        bridge    = var.network_bridge_secondary
        vlan_id   = var.vlan_id_secondary
        ipv4_addr = "${each.value.ip_address_secondary}/${var.network_cidr}"
        ipv4_gw   = null
      }
    } : {}
  )

  # Cloud-init configuration
  vm_init = {
    datastore_id = "local"
    dns = {
      servers = ["1.1.1.1", "8.8.8.8"]
    }
  }
}

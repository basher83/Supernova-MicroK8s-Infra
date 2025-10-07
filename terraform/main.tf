terraform {
  required_version = ">=1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.53.1"
    }
  }
}

provider "proxmox" {
  endpoint  = var.pve_api_url
  api_token = "${var.pve_token_id}=${var.pve_token_secret}"
  insecure  = false
}

# Main Cluster creation script for Proxmox
resource "proxmox_virtual_environment_vm" "k8s_nodes" {
  count     = length(var.cluster_vms)
  vm_id     = 300 + count.index
  name      = var.cluster_vms[count.index].name
  node_name = var.target_node
  started   = true

  clone {
    vm_id = var.vm_clone_template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = var.cluster_vms[count.index].cores
  }

  memory {
    dedicated = var.cluster_vms[count.index].memory
  }

  # Disk is whatever the hell the template has

  boot_order = ["virtio0"]

  network_device {
    bridge = var.cluster_network.bridge
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.cluster_vms[count.index].ip}${var.cluster_network.cidr_suffix}"
        gateway = var.cluster_network.gateway
      }
    }
  }
}

# Jumpbox VM for cluster access
resource "proxmox_virtual_environment_vm" "jumpbox" {
  vm_id     = 399
  name      = "jumpbox-ansible-k8s"
  node_name = var.target_node
  started   = true

  clone {
    vm_id = var.vm_clone_template_id
    full  = true
  }

  agent {
    enabled = true
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  network_device {
    bridge = var.home_network.bridge # real LAN access
  }

  network_device {
    bridge = var.cluster_network.bridge # cluster access
  }

  boot_order = ["virtio0"]

  initialization {
    ip_config {
      ipv4 {
        address = var.jumpbox_address
        gateway = var.home_network.gateway # home network router
      }
    }

    # Jumpbox cluster network configuration
    ip_config {
      ipv4 {
        address = "${var.jumpbox_cluster_ip}${var.cluster_network.cidr_suffix}"
      }
    }
  }
}

# Create Single VM
module "vm_minimal_config" {
  source = "github.com/trfore/terraform-bpg-proxmox//modules/vm-clone"

  node        = "pve"                   # required
  vm_id       = 100                     # required
  vm_name     = "vm-example-minimal"    # optional
  template_id = 9000                    # required
  ci_ssh_key  = "~/.ssh/id_ed25519.pub" # optional, add SSH key to "default" user
}

output "id" {
  value = module.vm_minimal_config.id
}

output "public_ipv4" {
  value = module.vm_minimal_config.public_ipv4
}

# Create Multiple VMs
module "vm_multiple_config" {
  source = "github.com/trfore/terraform-bpg-proxmox//modules/vm-clone"

  for_each = tomap({
    "vm-example-01" = {
      id       = 101
      template = 9000
    },
    "vm-example-02" = {
      id       = 102
      template = 9022
    },
  })

  node        = "pve"                   # required
  vm_id       = each.value.id           # required
  vm_name     = each.key                # optional
  template_id = each.value.template     # required
  ci_ssh_key  = "~/.ssh/id_ed25519.pub" # optional, add SSH key to "default" user
}

output "id_multiple_vms" {
  value = { for k, v in module.vm_multiple_config : k => v.id }
}

output "public_ipv4_multiple_vms" {
  value = { for k, v in module.vm_multiple_config : k => flatten(v.public_ipv4) }
}

# Create Single VM with Additional Disks
module "vm_disk_config" {
  source = "github.com/trfore/terraform-bpg-proxmox//modules/vm-clone"

  node        = "pve"                   # required
  vm_id       = 103                     # required
  vm_name     = "vm-example-disks"      # optional
  template_id = 9000                    # required
  ci_ssh_key  = "~/.ssh/id_ed25519.pub" # optional, add SSH key to "default" user
  disks = [
    {
      disk_interface = "scsi0", # default cloud image boot drive
      disk_size      = 10,
    },
    {
      disk_interface = "scsi1", # example add extra disk
      disk_size      = 4,
    },
  ]
}

# Create Single VM using UEFI
module "vm_uefi_config" {
  source = "github.com/trfore/terraform-bpg-proxmox//modules/vm-clone"

  node        = "pve"                   # required
  vm_id       = 104                     # required
  vm_name     = "vm-example-uefi"       # optional
  template_id = 9000                    # required
  bios        = "ovmf"                  # optional, set UEFI bios
  ci_ssh_key  = "~/.ssh/id_ed25519.pub" # optional, add SSH key to "default" user
}

# Create VM on Node ('pve1') With the Template Residing on Another Node ('pve')
# - This will initially create the VM on the `template_node` then migrate the VM
#   to the `node`.
module "vm_centralized_templates" {
  source = "github.com/trfore/terraform-bpg-proxmox//modules/vm-clone"

  node          = "pve1"                     # required
  vm_id         = 105                        # required
  vm_name       = "vm-centralized-templates" # optional
  template_node = "pve"                      # optional
  template_id   = 9000                       # required
  ci_ssh_key    = "~/.ssh/id_ed25519.pub"    # optional, add SSH key to "default" user
}

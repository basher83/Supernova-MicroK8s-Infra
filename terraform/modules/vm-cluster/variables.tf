# Copyright 2025 RalZareck
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# =============================================================================
# = Cluster Configuration =====================================================
# =============================================================================

variable "nodes" {
  description = <<-EOT
    Map of cluster nodes with their configuration. Each key is the VM name.
    Required per-node fields: pve_node, ip_address
    Optional per-node fields: cpu_cores, memory, disk_size, disk_datastore, tags, vm_id, vlan_id, mac_address, ip_address_secondary
  EOT
  type = map(object({
    pve_node             = string           # Proxmox node to deploy on
    ip_address           = string           # Primary NIC IP address (without CIDR)
    ip_address_secondary = optional(string) # Secondary NIC IP address (without CIDR)
    cpu_cores            = optional(number) # Override default CPU cores
    memory               = optional(number) # Override default memory (MB)
    disk_size            = optional(number) # Override default disk size (GB)
    disk_datastore       = optional(string) # Override default disk datastore
    efi_datastore        = optional(string) # Override EFI disk datastore
    tags                 = optional(list(string), [])
    vm_id                = optional(number)
    vlan_id              = optional(number)
    mac_address          = optional(string)
    network_bridge       = optional(string) # Override default network bridge
    boot_order           = optional(number, 0)
    user_data_file_id    = optional(string) # Custom cloud-init user data file
    template_node        = optional(string) # Override template source node
  }))

  validation {
    condition = alltrue([
      for name, node in var.nodes :
      can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", node.ip_address))
    ])
    error_message = "All node IP addresses must be valid IPv4 addresses without CIDR notation (e.g., '192.168.1.100')"
  }
}

variable "cluster_tags" {
  description = "Tags to apply to all VMs in the cluster (in addition to per-node tags)"
  type        = list(string)
  default     = []
}

# =============================================================================
# = Template Configuration ====================================================
# =============================================================================

variable "template_id" {
  description = "VM template ID to clone from (must be pre-existing)"
  type        = number

  validation {
    condition     = var.template_id > 0
    error_message = "Template ID must be a positive integer"
  }
}

variable "template_datastore" {
  description = "Datastore where template resides and where VM disks will be created"
  type        = string
  default     = "local-lvm"
}

variable "template_node" {
  description = "Proxmox node where the template is located (for cross-node cloning)"
  type        = string
  default     = null
}

# =============================================================================
# = Default Hardware Configuration ============================================
# =============================================================================

variable "default_cpu_cores" {
  description = "Default CPU cores for all nodes (can be overridden per node)"
  type        = number
  default     = 4
}

variable "default_memory" {
  description = "Default memory in MB for all nodes (can be overridden per node)"
  type        = number
  default     = 8192
}

variable "cpu_type" {
  description = "CPU type for all nodes"
  type        = string
  default     = "host"
}

variable "vm_bios" {
  description = "BIOS type for all VMs"
  type        = string
  default     = "ovmf"

  validation {
    condition     = contains(["ovmf", "seabios"], var.vm_bios)
    error_message = "vm_bios must be 'ovmf' or 'seabios'"
  }
}

variable "vm_machine" {
  description = "Machine type for all VMs"
  type        = string
  default     = "q35"

  validation {
    condition     = contains(["pc", "q35"], var.vm_machine)
    error_message = "vm_machine must be 'pc' or 'q35'"
  }
}

variable "vm_os" {
  description = "Operating system type for all VMs"
  type        = string
  default     = "l26"
}

variable "vm_agent" {
  description = "QEMU guest agent configuration for all VMs"
  type = object({
    enabled = optional(bool, true)
    timeout = optional(string, "15m")
    trim    = optional(bool, false)
    type    = optional(string, "virtio")
  })
  default = {
    enabled = true
    timeout = "15m"
  }
}

variable "vm_display" {
  description = "Display configuration for all VMs"
  type = object({
    type   = optional(string, "std")
    memory = optional(number, 16)
  })
  default = {}
}

# =============================================================================
# = Disk Configuration ========================================================
# =============================================================================

variable "disk_configuration" {
  description = "Default disk configuration for all nodes"
  type = map(object({
    size        = number
    file_format = optional(string, "raw")
    iothread    = optional(bool, true)
    ssd         = optional(bool, true)
    discard     = optional(string, "on")
    main_disk   = optional(bool, false)
  }))
  default = {
    scsi0 = {
      size      = 50
      main_disk = true
    }
  }

  validation {
    condition     = alltrue([for k, v in var.disk_configuration : can(regex("(?:scsi|sata|virtio)\\d+", k))])
    error_message = "Disk keys must follow the pattern: scsi[N], sata[N], or virtio[N]"
  }
}

# =============================================================================
# = Network Configuration =====================================================
# =============================================================================

variable "network_interfaces" {
  description = "Network interface configuration template for all nodes"
  type = map(object({
    bridge     = string
    firewall   = optional(bool, false)
    model      = optional(string, "virtio")
    mtu        = optional(number, 1500)
    rate_limit = optional(string)
    vlan_id    = optional(number)
  }))
  default = {
    net0 = {
      bridge = "vmbr0"
    }
    net1 = {
      bridge = "vmbr1"
    }
  }

  validation {
    condition     = alltrue([for k, v in var.network_interfaces : can(regex("net\\d+", k))])
    error_message = "Network interface keys must follow the pattern: net[N]"
  }
}

variable "network_cidr" {
  description = "Network CIDR suffix for all nodes (e.g., '24' for /24)"
  type        = string
  default     = "24"

  validation {
    condition     = can(regex("^[0-9]{1,2}$", var.network_cidr)) && tonumber(var.network_cidr) >= 0 && tonumber(var.network_cidr) <= 32
    error_message = "network_cidr must be a number between 0 and 32"
  }
}

variable "network_gateway" {
  description = "Network gateway IP for all nodes"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$", var.network_gateway))
    error_message = "network_gateway must be a valid IPv4 address"
  }
}

# =============================================================================
# = Cloud-Init Configuration ==================================================
# =============================================================================

variable "cloud_init_config" {
  description = "Cloud-init configuration for all nodes"
  type = object({
    datastore_id = string
    interface    = optional(string, "ide0")
    dns = optional(object({
      domain  = optional(string)
      servers = optional(list(string))
    }))
    user = optional(object({
      name     = optional(string)
      password = optional(string)
      keys     = optional(list(string))
    }))
  })

  validation {
    condition     = can(regex("(?:scsi|sata|ide)\\d+", var.cloud_init_config.interface))
    error_message = "cloud_init_config.interface must follow pattern: scsi[N], sata[N], or ide[N]"
  }
}

variable "custom_user_data_file_id" {
  description = "Optional custom cloud-init user data file ID to use for all nodes"
  type        = string
  default     = null
}

# =============================================================================
# = VM Start Configuration ====================================================
# =============================================================================

variable "start_on_deploy" {
  description = "Start VMs immediately after deployment"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Start VMs automatically when Proxmox node boots"
  type        = bool
  default     = true
}

variable "boot_up_delay" {
  description = "Delay in seconds before starting VMs on boot"
  type        = number
  default     = 0
}

variable "boot_down_delay" {
  description = "Delay in seconds when shutting down VMs"
  type        = number
  default     = 0
}

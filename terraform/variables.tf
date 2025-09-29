# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "homelab"
}

# Proxmox Configuration
variable "pve_api_url" {
  description = "Proxmox API endpoint URL"
  type        = string
  default     = "https://192.168.1.100:8006/"
}

variable "pve_api_token" {
  description = "Proxmox API token for authentication"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Allow insecure TLS connections to Proxmox"
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for connecting to Proxmox nodes"
  type        = string
  default     = "root"
}

variable "target_node_1" {
  description = "First Proxmox node for VM deployment"
  type        = string
  default     = "pve01"
}

variable "target_node_2" {
  description = "Second Proxmox node for VM deployment"
  type        = string
  default     = "pve02"
}

variable "target_node_3" {
  description = "Third Proxmox node for VM deployment"
  type        = string
  default     = "pve03"
}

variable "template_id" {
  description = "ID of the VM template to clone"
  type        = number
}

# Network Configuration
variable "home_network" {
  description = "Home network configuration"
  type = object({
    gateway = string
    bridge  = string
  })
  default = {
    gateway = "192.168.30.1"
    bridge  = "vmbr0"
  }
}

variable "cluster_network" {
  description = "Cluster network configuration"
  type = object({
    gateway     = string
    bridge      = string
    cidr_suffix = string
  })
  default = {
    gateway     = "192.168.4.1"
    bridge      = "vmbr1"
    cidr_suffix = "/24"
  }
}

# Jumpbox Configuration
variable "jumpbox_home_ip" {
  description = "Jumpbox IP on home network (with CIDR)"
  type        = string
  default     = "192.168.30.240/24"
}

variable "jumpbox_cluster_ip" {
  description = "Jumpbox IP on cluster network (without CIDR)"
  type        = string
  default     = "192.168.4.240"
}

# VM Specifications
variable "node_specs" {
  description = "Specifications for MicroK8s nodes"
  type = object({
    cpu_cores = number
    memory    = number
  })
  default = {
    cpu_cores = 2
    memory    = 4096
  }
}

# Advanced VM Configuration
variable "machine_type" {
  description = "Machine type for VMs"
  type        = string
  default     = "q35"
}

variable "bios_type" {
  description = "BIOS type for VMs"
  type        = string
  default     = "ovmf"
}

variable "efi_disk_enabled" {
  description = "Enable EFI disk for UEFI boot"
  type        = bool
  default     = true
}

variable "vm_description" {
  description = "Description for VMs"
  type        = string
  default     = "Managed by Terraform"
}

variable "disk_datastore_id" {
  description = "Datastore ID for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 32
}

variable "disk_iothread" {
  description = "Enable I/O threads for disk"
  type        = bool
  default     = true
}

variable "disk_discard" {
  description = "Enable discard for disk"
  type        = string
  default     = "on"
}

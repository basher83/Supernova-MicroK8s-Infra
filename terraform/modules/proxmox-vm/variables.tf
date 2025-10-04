variable "vm_id" {
  description = "The ID of the VM"
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999999
    error_message = "VM ID must be between 100 and 999999999."
  }
}

variable "vm_name" {
  description = "The name of the VM"
  type        = string
}

variable "target_node" {
  description = "The Proxmox node to deploy the VM on"
  type        = string
}

variable "template_id" {
  description = "The ID of the template to clone from"
  type        = number
}

variable "template_node" {
  description = "The Proxmox node where the template exists"
  type        = string
  default     = "lloyd"
}

variable "start_on_boot" {
  description = "Whether to start the VM on boot"
  type        = bool
  default     = true
}

variable "qemu_agent" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "CPU type"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "machine_type" {
  description = "Machine type for VM"
  type        = string
  default     = "q35"
}

variable "bios_type" {
  description = "BIOS type for VM"
  type        = string
  default     = "seabios"

  validation {
    condition     = contains(["ovmf", "seabios"], var.bios_type)
    error_message = "BIOS type must be either 'ovmf' or 'seabios'."
  }
}

variable "efi_disk_enabled" {
  description = "Enable EFI disk for UEFI boot"
  type        = bool
  default     = true
}

variable "vm_description" {
  description = "Description for the VM"
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

  validation {
    condition     = contains(["on", "ignore"], var.disk_discard)
    error_message = "Disk discard must be either 'on' or 'ignore'."
  }
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "network_interfaces" {
  description = "List of network interfaces"
  type = list(object({
    bridge = string
    model  = optional(string)
  }))
  default = []
}

variable "cloud_init_enabled" {
  description = "Enable cloud-init"
  type        = bool
  default     = true
}

variable "ip_configs" {
  description = "List of IP configurations for cloud-init"
  type = list(object({
    ipv4_address = string
    ipv4_gateway = optional(string)
    ipv6_address = optional(string)
    ipv6_gateway = optional(string)
  }))
  default = []
}

variable "tags" {
  description = "Tags to apply to the VM (list of strings)"
  type        = list(string)
  default     = []
}

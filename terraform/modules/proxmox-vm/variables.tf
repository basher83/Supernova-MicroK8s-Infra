variable "vm_id" {
  description = "The ID of the VM"
  type        = number
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
  default     = "host"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "boot_order" {
  description = "Boot order"
  type        = list(string)
  default     = ["virtio0"]
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

variable "user_data_file_id" {
  description = "User data file ID for cloud-init"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the VM"
  type        = map(string)
  default     = {}
}
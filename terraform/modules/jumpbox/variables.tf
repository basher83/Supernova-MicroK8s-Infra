variable "vm_id" {
  description = "VM ID for the jumpbox"
  type        = number
  default     = 399
}

variable "vm_name" {
  description = "Name of the jumpbox VM"
  type        = string
  default     = "jumpbox-ansible-k8s"
}

variable "target_node" {
  description = "Proxmox node to deploy VM on"
  type        = string
}

variable "template_id" {
  description = "ID of the VM template to clone"
  type        = number
}

variable "cpu_cores" {
  description = "Number of CPU cores for jumpbox"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB for jumpbox"
  type        = number
  default     = 512
}

variable "home_network" {
  description = "Home network configuration"
  type = object({
    gateway = string
    bridge  = string
  })
}

variable "home_network_ip" {
  description = "IP address on home network (with CIDR)"
  type        = string
  default     = "192.168.30.240/24"
}

variable "cluster_network" {
  description = "Cluster network configuration"
  type = object({
    gateway     = string
    bridge      = string
    cidr_suffix = string
  })
}

variable "cluster_network_ip" {
  description = "IP address on cluster network (without CIDR)"
  type        = string
  default     = "192.168.3.250"
}

variable "common_tags" {
  description = "Common tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "machine_type" {
  description = "Machine type for VM"
  type        = string
  default     = "q35"
}

variable "bios_type" {
  description = "BIOS type for VM"
  type        = string
  default     = "ovmf"
}

variable "efi_disk_enabled" {
  description = "Enable EFI disk for UEFI boot"
  type        = bool
  default     = true
}

variable "vm_description" {
  description = "Description for the VM"
  type        = string
  default     = "Jumpbox managed by Terraform"
}

variable "disk_datastore_id" {
  description = "Datastore ID for VM disks"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = number
  default     = 20
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

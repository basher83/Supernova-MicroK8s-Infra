# --- Shared Environment Variables ---

variable "vm_datastore" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox datastore to use for VM disks"
}

variable "vm_disk_size" {
  type        = number
  default     = 68
  description = "VM disk size in GB"
}

variable "vm_bridge_1" {
  type        = string
  default     = "vmbr0"
  description = "First network bridge"
}

variable "vm_bridge_2" {
  type        = string
  default     = "vmbr1"
  description = "Second network bridge"
}

variable "vm_tags" {
  type        = list(string)
  default     = ["terraform", "nomad", "development"]
  description = "Default tags for all VMs"
}

variable "ci_ssh_key" {
  type        = string
  sensitive   = true
  description = "SSH public key for cloud-init"
}

variable "cloud_init_username" {
  type        = string
  default     = "ubuntu"
  description = "Username for cloud-init"
}


variable "pve_api_url" {
  type        = string
  description = "Proxmox API endpoint URL"
}

variable "pve_api_token" {
  type        = string
  sensitive   = true
  description = "Proxmox API token ID"
}

variable "proxmox_insecure" {
  description = "Set true to skip TLS verification for Proxmox API (not recommended in production)"
  type        = bool
  default     = true # Development may use self-signed certs
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host connections (required for file uploads)"
  type        = string
  default     = "root"
}

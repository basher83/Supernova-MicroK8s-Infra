# --- Shared Environment Variables ---

variable "vm_datastore" {
  description = "Target datastore for VM disks (e.g., local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "vm_disk_size" {
  description = "Boot disk size in GiB"
  type        = number
  default     = 68
}

variable "vm_bridge_1" {
  description = "Primary network bridge for NIC0"
  type        = string
  default     = "vmbr0"
}

variable "vm_bridge_2" {
  description = "Secondary network bridge for NIC1 (if dual NIC enabled)"
  type        = string
  default     = "vmbr1"
}

variable "vm_tags" {
  type        = list(string)
  default     = ["terraform", "nomad", "staging"]
  description = "Default tags for all VMs"
}

variable "ci_ssh_key" {
  description = "SSH public key injected via cloud-init for VM access"
  type        = string
  sensitive   = true
}

variable "cloud_init_username" {
  description = "Default username provisioned via cloud-init on the VM"
  type        = string
  default     = "ubuntu"
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
  default     = true # Staging may use self-signed certs
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host connections (required for file uploads)"
  type        = string
  default     = "root"
}

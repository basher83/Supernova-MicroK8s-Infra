# --- Vault Cluster Configuration ---

variable "vault_network_subnet" {
  type        = string
  default     = "192.168.10"
  description = "Network subnet for Vault cluster (without last octet)"
}

variable "template_id" {
  type        = number
  default     = 8000 # Ubuntu 22.04 template
  description = "Template ID for VM cloning"
}

variable "template_node" {
  type        = string
  default     = "lloyd"
  description = "Node where the template VM exists"
}

# --- Shared Environment Variables ---

variable "vm_datastore" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox datastore for VM disks"
}

variable "vm_bridge_1" {
  type        = string
  default     = "vmbr0"
  description = "Primary network bridge for VMs"
}

variable "vm_tags" {
  type        = list(string)
  default     = ["terraform", "vault", "production", "hercules"]
  description = "Default tags for all VMs"
}

variable "ci_ssh_key" {
  type      = string
  sensitive = true
}

variable "cloud_init_username" {
  type    = string
  default = "ubuntu"
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
  default     = false # Production should use valid certificates
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host connections (required for file uploads)"
  type        = string
  default     = "root"
}

variable "dns_servers" {
  description = "List of DNS servers for vault VMs"
  type        = list(string)
  default     = ["8.8.8.8", "8.8.4.4"]
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "homelab"
}

# Proxmox Configuration
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.100:8006/"
}

variable "proxmox_username" {
  description = "Proxmox username"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "target_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
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
    gateway = "192.168.1.1"
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

# SSH Configuration
variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}

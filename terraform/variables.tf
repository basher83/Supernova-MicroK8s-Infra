variable "pm_password" {}
variable "template_id" {}
variable "target_node" {}
variable "ssh_public_key" {}
variable "vmbr_name" {
  default = "vmbr1"
}
variable "cluster_vms" {
  type = list(object({
    name   = string
    ip     = string
    cores  = number
    memory = number
    disk   = number
  }))
}

variable "jumpbox_address" {
  default = "192.168.1.240/24"
}

# Network Configuration
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint"
  type        = string
  default     = "https://192.168.1.100:8006/"
}

variable "home_network" {
  description = "Home network configuration"
  type = object({
    gateway     = string
    bridge      = string
    cidr_suffix = string
  })
  default = {
    gateway     = "192.168.1.1"
    bridge      = "vmbr0"
    cidr_suffix = "/24"
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
    gateway     = "192.168.3.1"
    bridge      = "vmbr1"
    cidr_suffix = "/24"
  }
}

# Cluster Configuration
variable "cluster_ips" {
  description = "IP addresses for cluster nodes"
  type = object({
    masters = list(string)
    workers = list(string)
  })
  default = {
    masters = ["192.168.3.11", "192.168.3.12"]
    workers = ["192.168.3.21", "192.168.3.22", "192.168.3.23"]
  }
}

variable "jumpbox_cluster_ip" {
  description = "Jumpbox IP on cluster network"
  type        = string
  default     = "192.168.3.250"
}

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
  default     = "192.168.1.240/24"
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
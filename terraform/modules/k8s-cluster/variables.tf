variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "microk8s"
}

variable "target_node" {
  description = "Proxmox node to deploy VMs on"
  type        = string
}

variable "template_id" {
  description = "ID of the VM template to clone"
  type        = number
}

variable "master_nodes" {
  description = "Configuration for master nodes"
  type = list(object({
    vm_id      = number
    name       = string
    ip_address = string
    cpu_cores  = number
    memory     = number
  }))
}

variable "worker_nodes" {
  description = "Configuration for worker nodes"
  type = list(object({
    vm_id      = number
    name       = string
    ip_address = string
    cpu_cores  = number
    memory     = number
  }))
}

variable "cluster_network" {
  description = "Cluster network configuration"
  type = object({
    gateway     = string
    bridge      = string
    cidr_suffix = string
  })
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
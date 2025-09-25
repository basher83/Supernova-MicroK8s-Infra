output "cluster_summary" {
  description = "Cluster deployment summary"
  value = {
    cluster_name = local.cluster_name
    environment  = var.environment
    node_count   = module.k8s_cluster.cluster_info.total_nodes
    master_count = module.k8s_cluster.cluster_info.master_count
    worker_count = module.k8s_cluster.cluster_info.worker_count
  }
}

output "master_nodes" {
  description = "Master node details"
  value       = module.k8s_cluster.master_nodes
}

output "worker_nodes" {
  description = "Worker node details"
  value       = module.k8s_cluster.worker_nodes
}

output "jumpbox_info" {
  description = "Jumpbox connection information"
  value = {
    vm_name            = module.jumpbox.vm_name
    ssh_connection     = module.jumpbox.ssh_connection
    home_network_ip    = module.jumpbox.home_network_ip
    cluster_network_ip = module.jumpbox.cluster_network_ip
  }
}

output "network_info" {
  description = "Network configuration"
  value = {
    home_network    = var.home_network
    cluster_network = var.cluster_network
    master_ips      = module.k8s_cluster.master_ips
    worker_ips      = module.k8s_cluster.worker_ips
  }
}

output "ansible_inventory" {
  description = "Ansible inventory in YAML format"
  value       = yamlencode(local.ansible_inventory)
}

output "ansible_proxy_config" {
  description = "Ansible SSH proxy configuration via jumpbox"
  value = {
    proxy_command = "ssh -o StrictHostKeyChecking=no -W %h:%p ansible@${module.jumpbox.home_network_ip}"
    ssh_config = <<-EOT
      Host jumpbox
        HostName ${module.jumpbox.home_network_ip}
        User ansible
        StrictHostKeyChecking no

      Host master-* worker-*
        ProxyJump jumpbox
        User ansible
        StrictHostKeyChecking no
    EOT
  }
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value = <<-EOT
    Infrastructure deployed successfully!

    1. SSH to jumpbox:
       ${module.jumpbox.ssh_connection}

    2. Configure Ansible inventory:
       terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

    3. Run Ansible playbook:
       cd ../ansible
       ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml

    4. Access cluster from jumpbox:
       ssh master-1
       microk8s kubectl get nodes
  EOT
}
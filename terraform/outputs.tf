output "cluster_summary" {
  description = "Cluster deployment summary"
  value = {
    cluster_name = local.cluster_name
    environment  = var.environment
    node_count   = length(local.microk8s_nodes)
    node_names   = [for node in local.microk8s_nodes : node.name]
  }
}

output "microk8s_nodes" {
  description = "MicroK8s node details"
  value       = { for k, v in module.microk8s_nodes : k => v }
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
    node_ips        = [for node in local.microk8s_nodes : node.ip_address]
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
    ssh_config    = <<-EOT
      Host jumpbox
        HostName ${module.jumpbox.home_network_ip}
        User ansible
        StrictHostKeyChecking no

      Host microk8s-*
        ProxyJump jumpbox
        User ansible
        StrictHostKeyChecking no
    EOT
  }
}

output "next_steps" {
  description = "Next steps after infrastructure deployment"
  value       = <<-EOT
    Infrastructure deployed successfully!

    1. SSH to jumpbox:
       ${module.jumpbox.ssh_connection}

    2. Configure Ansible inventory:
       terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

    3. Run Ansible playbook:
       cd ../ansible
       ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml

    4. Access cluster via jumpbox:
       ssh microk8s-1
       microk8s kubectl get nodes
  EOT
}

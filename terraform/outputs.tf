output "cluster_summary" {
  description = "Cluster deployment summary"
  value = {
    cluster_name = local.cluster_name
    environment  = var.environment
    vm_count     = length(local.vm_instances)
    vm_names     = [for name, config in local.vm_instances : name]
  }
}

output "vm_details" {
  description = "All VM deployment details"
  value       = { for k, v in module.vm : k => v }
}

output "microk8s_nodes" {
  description = "MicroK8s node details"
  value = {
    for name, config in local.vm_instances :
    name => module.vm[name]
    if config.role == "microk8s-node"
  }
}

output "jumpbox_info" {
  description = "Jumpbox connection information"
  value = {
    vm_name            = module.vm["jumpbox"].vm_name
    vm_id              = module.vm["jumpbox"].vm_id
    node               = module.vm["jumpbox"].node
    home_network_ip    = split("/", local.vm_instances["jumpbox"].ip)[0]
    cluster_network_ip = local.vm_instances["jumpbox"].cluster_ip != "" ? "${local.vm_instances["jumpbox"].cluster_ip}${var.cluster_network.cidr_suffix}" : null
    ssh_connection     = "ssh ansible@${split("/", local.vm_instances["jumpbox"].ip)[0]}"
  }
}

output "network_info" {
  description = "Network configuration"
  value = {
    home_network    = var.home_network
    cluster_network = var.cluster_network
    node_ips        = [
      for name, config in local.vm_instances :
      split("/", config.ip)[0]
      if config.role == "microk8s-node"
    ]
  }
}

output "ansible_inventory" {
  description = "Ansible inventory in YAML format"
  value       = yamlencode(local.ansible_inventory)
}

output "ansible_proxy_config" {
  description = "Ansible SSH proxy configuration via jumpbox"
  value = {
    proxy_command = "ssh -o StrictHostKeyChecking=no -W %h:%p ansible@${split("/", local.vm_instances["jumpbox"].ip)[0]}"
    ssh_config    = <<-EOT
      Host jumpbox
        HostName ${split("/", local.vm_instances["jumpbox"].ip)[0]}
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
       ssh ansible@${split("/", local.vm_instances["jumpbox"].ip)[0]}

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

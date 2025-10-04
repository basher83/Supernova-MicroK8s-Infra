# Ansible Inventory Output
# Generate a complete Ansible inventory in YAML format
output "ansible_inventory" {
  description = "Ansible inventory in YAML format - save to ../ansible/inventory/terraform.yml"
  value       = <<-EOT
    # Ansible Inventory for Supernova-MicroK8s Cluster
    # Auto-generated from Terraform
    # Usage: terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml
    all:
      children:
        jumpbox_vm:
          hosts:
            jumpbox:
              ansible_host: ${split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]}
              ansible_user: ansible
              vm_id: ${module.vm["jumpbox"].vm_id}
              proxmox_node: ${module.vm["jumpbox"].node}
              cluster_ip: ${split("/", module.vm["jumpbox"].ip_addresses[1].ipv4)[0]}

        microk8s_nodes:
          vars:
            ansible_user: ansible
          children:
            microk8s:
              hosts:
                %{for key, vm in local.vm_instances~}
                %{if vm.role == "microk8s-node"~}
                ${key}:
                  ansible_host: ${split("/", module.vm[key].ip_addresses[0].ipv4)[0]}
                  vm_id: ${module.vm[key].vm_id}
                  proxmox_node: ${module.vm[key].node}
                %{endif~}
                %{endfor~}
  EOT
}

# Ansible SSH Configuration Output
output "ansible_ssh_config" {
  description = "SSH configuration for Ansible - add to ~/.ssh/config"
  value       = <<-EOT
    # Terraform-generated SSH config for MicroK8s cluster

    Host jumpbox
      HostName ${split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]}
      User ansible
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null

    Host microk8s-*
      User ansible
      ProxyJump jumpbox
      StrictHostKeyChecking no
      UserKnownHostsFile /dev/null

    %{for key, vm in local.vm_instances~}
    %{if vm.role == "microk8s-node"~}
    Host ${key}
      HostName ${split("/", module.vm[key].ip_addresses[0].ipv4)[0]}

    %{endif~}
    %{endfor~}
  EOT
}

# Quick reference outputs
output "jumpbox_ip" {
  description = "Jumpbox home network IP address"
  value       = split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]
}

output "jumpbox_cluster_ip" {
  description = "Jumpbox cluster network IP address"
  value       = split("/", module.vm["jumpbox"].ip_addresses[1].ipv4)[0]
}

output "microk8s_nodes" {
  description = "MicroK8s node details"
  value = {
    for key, vm in local.vm_instances : key => {
      ip           = split("/", module.vm[key].ip_addresses[0].ipv4)[0]
      vm_id        = module.vm[key].vm_id
      proxmox_node = module.vm[key].node
    } if vm.role == "microk8s-node"
  }
}

# Next steps guidance
output "next_steps" {
  description = "Post-deployment instructions"
  value       = <<-EOT
    ╔══════════════════════════════════════════════════════════════════════════════╗
    ║                    Infrastructure Deployment Complete!                       ║
    ╚══════════════════════════════════════════════════════════════════════════════╝

    📋 Next Steps:

    1. Generate Ansible inventory:
       terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

    2. Test connectivity:
       ssh ansible@${split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]}

    3. Run Ansible playbook:
       cd ../ansible
       ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml

    4. Verify cluster status (via jumpbox):
       ssh ${split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]}
       ssh microk8s-1
       microk8s kubectl get nodes

    📌 Quick Access:
       Jumpbox:     ssh ansible@${split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]}
       MicroK8s-1:  ssh microk8s-1  (via jumpbox)
       MicroK8s-2:  ssh microk8s-2  (via jumpbox)
       MicroK8s-3:  ssh microk8s-3  (via jumpbox)
  EOT
}

# Cluster summary
output "cluster_summary" {
  description = "Cluster deployment summary"
  value = {
    environment   = var.environment
    total_vms     = length(local.vm_instances)
    jumpbox       = module.vm["jumpbox"].vm_name
    jumpbox_ip    = split("/", module.vm["jumpbox"].ip_addresses[0].ipv4)[0]
    microk8s_nodes = [
      for key, vm in local.vm_instances : {
        name = key
        ip   = split("/", module.vm[key].ip_addresses[0].ipv4)[0]
        node = module.vm[key].node
      } if vm.role == "microk8s-node"
    ]
  }
}

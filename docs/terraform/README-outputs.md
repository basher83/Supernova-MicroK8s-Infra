# Terraform Outputs Documentation

This document describes the Terraform outputs available for the Supernova MicroK8s infrastructure and how to use them with Ansible.

## Available Outputs

### `ansible_inventory`

Generates a complete Ansible inventory in YAML format compatible with your Ansible configuration.

**Usage:**

```bash
# Generate and save to Ansible inventory directory
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

# Or use the helper script
../scripts/generate-ansible-inventory.sh
```

**Output Format:**

```yaml
all:
  children:
    jumpbox_vm:
      hosts:
        jumpbox:
          ansible_host: 192.168.30.240
          ansible_user: ansible
          vm_id: 399
          proxmox_node: holly
          cluster_ip: 192.168.4.240

    microk8s_nodes:
      vars:
        ansible_user: ansible
      children:
        microk8s:
          hosts:
            microk8s-1:
              ansible_host: 192.168.4.11
              vm_id: 311
              proxmox_node: lloyd
            microk8s-2:
              ansible_host: 192.168.4.12
              vm_id: 312
              proxmox_node: mable
            microk8s-3:
              ansible_host: 192.168.4.13
              vm_id: 313
              proxmox_node: holly
```

### `ansible_ssh_config`

Generates SSH configuration for accessing the cluster via the jumpbox.

**Usage:**

```bash
# View SSH configuration
terraform output -raw ansible_ssh_config

# Append to your SSH config
terraform output -raw ansible_ssh_config >> ~/.ssh/config
```

**Output Format:**

```ssh-config
Host jumpbox
  HostName 192.168.30.240
  User ansible
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host microk8s-*
  User ansible
  ProxyJump jumpbox
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null

Host microk8s-1
  HostName 192.168.4.11

Host microk8s-2
  HostName 192.168.4.12

Host microk8s-3
  HostName 192.168.4.13
```

### `jumpbox_ip`

Returns the jumpbox home network IP address.

```bash
terraform output jumpbox_ip
# Output: 192.168.30.240
```

### `jumpbox_cluster_ip`

Returns the jumpbox cluster network IP address.

```bash
terraform output jumpbox_cluster_ip
# Output: 192.168.4.240
```

### `microk8s_nodes`

Returns a map of MicroK8s node details.

```bash
terraform output microk8s_nodes
```

**Output:**

```hcl
{
  "microk8s-1" = {
    "ip" = "192.168.4.11"
    "proxmox_node" = "lloyd"
    "vm_id" = 311
  }
  "microk8s-2" = {
    "ip" = "192.168.4.12"
    "proxmox_node" = "mable"
    "vm_id" = 312
  }
  "microk8s-3" = {
    "ip" = "192.168.4.13"
    "proxmox_node" = "holly"
    "vm_id" = 313
  }
}
```

### `cluster_summary`

Returns a comprehensive summary of the deployed cluster.

```bash
terraform output cluster_summary
```

**Output:**

```hcl
{
  "environment" = "homelab"
  "jumpbox" = "jumpbox-ansible-k8s"
  "jumpbox_ip" = "192.168.30.240"
  "microk8s_nodes" = [
    {
      "ip" = "192.168.4.11"
      "name" = "microk8s-1"
      "node" = "lloyd"
    },
    {
      "ip" = "192.168.4.12"
      "name" = "microk8s-2"
      "node" = "mable"
    },
    {
      "ip" = "192.168.4.13"
      "name" = "microk8s-3"
      "node" = "holly"
    },
  ]
  "total_vms" = 4
}
```

### `next_steps`

Displays post-deployment instructions.

```bash
terraform output next_steps
```

## Common Workflows

### 1. Initial Deployment

```bash
# Deploy infrastructure
terraform apply

# Generate Ansible inventory
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

# Or use the helper script
../scripts/generate-ansible-inventory.sh

# Test connectivity
ssh ansible@$(terraform output -raw jumpbox_ip)

# Configure cluster with Ansible
cd ../ansible
ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml
```

### 2. Quick SSH Access

```bash
# SSH to jumpbox
ssh ansible@$(terraform output -raw jumpbox_ip)

# SSH to MicroK8s nodes (from your local machine with SSH config)
terraform output -raw ansible_ssh_config >> ~/.ssh/config
ssh microk8s-1
```

### 3. Ansible Automation

```bash
# Generate inventory
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

# Test Ansible connectivity
cd ../ansible
ansible all -i inventory/terraform.yml -m ping

# Run specific playbook
ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml

# Ad-hoc command on all nodes
ansible microk8s -i inventory/terraform.yml -m shell -a "microk8s status"
```

### 4. Cluster Verification

```bash
# Get jumpbox IP
JUMPBOX_IP=$(terraform output -raw jumpbox_ip)

# SSH to jumpbox and access cluster
ssh ansible@${JUMPBOX_IP} << 'EOF'
  ssh microk8s-1
  microk8s kubectl get nodes
  microk8s kubectl get pods -A
EOF
```

### 5. Export All Outputs

```bash
# JSON format
terraform output -json > outputs.json

# View all outputs
terraform output

# Get specific output in raw format
terraform output -raw ansible_inventory
terraform output -raw ansible_ssh_config
```

## Helper Script

The repository includes a helper script to automate inventory generation:

### Usage

```bash
# From project root
./scripts/generate-ansible-inventory.sh
```

### What It Does

1. ✓ Validates Terraform state exists
2. ✓ Generates Ansible inventory from outputs
3. ✓ Validates inventory file syntax
4. ✓ Tests with Ansible (if available)
5. ✓ Displays next steps

### Output Example

```
╔══════════════════════════════════════════════════════════════╗
║        Generating Ansible Inventory from Terraform          ║
╚══════════════════════════════════════════════════════════════╝

→ Generating inventory from Terraform outputs...
✓ Inventory generated successfully!
  Location: ../ansible/inventory/terraform.yml

→ Validating inventory file...
✓ Inventory file is valid and not empty
  Lines: 28

→ Testing inventory with Ansible...
✓ Ansible can parse the inventory successfully

╔══════════════════════════════════════════════════════════════╗
║                    Summary                                   ║
╚══════════════════════════════════════════════════════════════╝

Inventory file: ../ansible/inventory/terraform.yml

Next steps:
  1. View inventory:
     cat ../ansible/inventory/terraform.yml

  2. Test connectivity:
     cd ../ansible
     ansible all -i inventory/terraform.yml -m ping

  3. Run playbook:
     ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml
```

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform

      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: ./terraform

      - name: Generate Ansible Inventory
        run: |
          terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml
        working-directory: ./terraform

      - name: Run Ansible Playbook
        run: |
          ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml
        working-directory: ./ansible
```

## Troubleshooting

### Output is empty

**Problem:** `terraform output` returns nothing

**Solution:**
```bash
# Ensure you've applied your configuration
terraform apply

# Check if outputs are defined
grep -A 5 "output" outputs.tf
```

### Invalid YAML in inventory

**Problem:** Ansible can't parse the generated inventory

**Solution:**
```bash
# Regenerate inventory
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml

# Validate YAML syntax
python3 -c "import yaml; yaml.safe_load(open('../ansible/inventory/terraform.yml'))"

# Or use yq if available
yq eval '../ansible/inventory/terraform.yml'
```

### IP addresses not resolving

**Problem:** Generated IPs don't match actual VMs

**Solution:**
```bash
# Refresh Terraform state
terraform refresh

# Regenerate outputs
terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml
```

### SSH connection fails

**Problem:** Can't connect via jumpbox

**Solution:**
```bash
# Test jumpbox connectivity
ssh -v ansible@$(terraform output -raw jumpbox_ip)

# Verify SSH config
terraform output -raw ansible_ssh_config

# Test ProxyJump manually
ssh -J ansible@192.168.30.240 ansible@192.168.4.11
```

## Best Practices

1. **Always regenerate inventory after changes:**
   ```bash
   terraform apply
   ./scripts/generate-ansible-inventory.sh
   ```

2. **Version control the inventory:**
   - Add `ansible/inventory/terraform.yml` to `.gitignore`
   - Generate dynamically in CI/CD pipelines

3. **Use the helper script:**
   - Includes validation and error checking
   - Consistent output formatting
   - Automated testing

4. **Keep outputs up to date:**
   ```bash
   # After any infrastructure change
   terraform refresh
   terraform output -raw ansible_inventory > ../ansible/inventory/terraform.yml
   ```

## See Also

- [Terraform Documentation](../README.md)
- [Ansible Documentation](../ansible/README.md)
- [Setup Guide](../docs/setup-guide.md)

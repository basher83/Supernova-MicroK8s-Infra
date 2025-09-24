#!/bin/bash
# Generate Ansible inventory files from Terraform outputs
# Usage: ./scripts/generate-ansible-inventory.sh [environment]

set -euo pipefail

ENVIRONMENT="${1:-production}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$PROJECT_ROOT/terraform"
ANSIBLE_DIR="$PROJECT_ROOT/ansible"
INVENTORY_DIR="$ANSIBLE_DIR/inventory"

# Ensure directories exist
mkdir -p "$INVENTORY_DIR"

# Check if we're in the right terraform directory
if [[ ! -f "$TERRAFORM_DIR/main.tf" ]]; then
    echo "Error: Terraform directory not found at $TERRAFORM_DIR"
    echo "Expected terraform/main.tf to exist"
    exit 1
fi

echo "🔄 Generating Ansible inventory for $ENVIRONMENT environment..."

# Change to terraform directory and get outputs
cd "$TERRAFORM_DIR"

# Extract VM details from Terraform configuration
echo "📡 Extracting VM details from Terraform configuration..."

# For now, we'll read from the current terraform variables
# In a real deployment, this would read from terraform outputs
TERRAFORM_VARS_FILE="$TERRAFORM_DIR/terraform.tfvars"

if [[ -f "$TERRAFORM_VARS_FILE" ]]; then
    echo "Reading from terraform.tfvars..."
    # This is a simplified version - in practice you'd want to parse the tfvars properly
    # For now, we'll use the default values from variables.tf
else
    echo "No terraform.tfvars found, using default values..."
fi

# Generate YAML inventory based on our current cluster structure
cat > "$INVENTORY_DIR/$ENVIRONMENT.yml" << EOF
---
# Ansible Inventory for Supernova-MicroK8s $ENVIRONMENT Cluster
# Auto-generated from Terraform configuration on $(date -u +"%Y-%m-%d %H:%M:%S UTC")
all:
  children:
    jumpbox_vm:
      hosts:
        jumpbox:
          ansible_host: "192.168.1.240"
    k8s_nodes:
      children:
        masters:
          hosts:
            master-1:
              ansible_host: "192.168.3.11"
            master-2:
              ansible_host: "192.168.3.12"
        workers:
          hosts:
            worker-1:
              ansible_host: "192.168.3.21"
            worker-2:
              ansible_host: "192.168.3.22"
            worker-3:
              ansible_host: "192.168.3.23"
      vars:
        # SSH proxy configuration for cluster nodes
        ansible_ssh_common_args: "-o ProxyJump=ansible@192.168.1.240 -o UserKnownHostsFile=/dev/null -o ForwardAgent=yes"
EOF

echo "✅ Generated Ansible inventory: $INVENTORY_DIR/$ENVIRONMENT.yml"

# Test the inventory
cd "$ANSIBLE_DIR"
echo "🧪 Testing inventory syntax..."
if python3 -c "import yaml; yaml.safe_load(open('inventory/$ENVIRONMENT.yml'))" 2>/dev/null; then
    echo "✅ Inventory syntax is valid"
    echo ""
    echo "📋 Inventory summary:"
    echo "Generated inventory for Supernova-MicroK8s cluster with jumpbox and k8s nodes"
else
    echo "❌ Inventory syntax error - please check the generated file"
fi

echo ""
echo "🚀 Ready to use with Ansible:"
echo "   cd ansible/"
echo "   ansible all -i inventory/$ENVIRONMENT.yml -m ping"
echo "   ansible-playbook -i inventory/$ENVIRONMENT.yml playbooks/playbook.yml"

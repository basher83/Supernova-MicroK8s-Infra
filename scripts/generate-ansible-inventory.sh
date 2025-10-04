#!/usr/bin/env bash

set -euo pipefail

# Script to generate Ansible inventory from Terraform outputs
# Usage: ./scripts/generate-ansible-inventory.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/terraform"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
INVENTORY_FILE="${ANSIBLE_DIR}/inventory/terraform.yml"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        Generating Ansible Inventory from Terraform          ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if terraform directory exists
if [ ! -d "${TERRAFORM_DIR}" ]; then
    echo -e "${RED}Error: Terraform directory not found: ${TERRAFORM_DIR}${NC}"
    exit 1
fi

# Check if terraform state exists
if [ ! -f "${TERRAFORM_DIR}/terraform.tfstate" ]; then
    echo -e "${RED}Error: Terraform state not found. Run 'terraform apply' first.${NC}"
    exit 1
fi

# Change to terraform directory
cd "${TERRAFORM_DIR}"

# Generate inventory
echo -e "${YELLOW}→${NC} Generating inventory from Terraform outputs..."
if terraform output -raw ansible_inventory > "${INVENTORY_FILE}"; then
    echo -e "${GREEN}✓${NC} Inventory generated successfully!"
    echo -e "  Location: ${INVENTORY_FILE}"
else
    echo -e "${RED}✗${NC} Failed to generate inventory"
    exit 1
fi

# Validate the inventory file
echo ""
echo -e "${YELLOW}→${NC} Validating inventory file..."
if [ -f "${INVENTORY_FILE}" ] && [ -s "${INVENTORY_FILE}" ]; then
    echo -e "${GREEN}✓${NC} Inventory file is valid and not empty"

    # Show file size and line count
    LINES=$(wc -l < "${INVENTORY_FILE}")
    echo -e "  Lines: ${LINES}"
else
    echo -e "${RED}✗${NC} Inventory file is invalid or empty"
    exit 1
fi

# Optional: Test inventory with ansible-inventory
echo ""
echo -e "${YELLOW}→${NC} Testing inventory with Ansible..."
cd "${ANSIBLE_DIR}"
if command -v ansible-inventory &> /dev/null; then
    if ansible-inventory -i "${INVENTORY_FILE}" --list > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} Ansible can parse the inventory successfully"
    else
        echo -e "${YELLOW}⚠${NC}  Warning: Ansible inventory validation failed"
        echo -e "  This might be okay if VMs are not yet accessible"
    fi
else
    echo -e "${YELLOW}⚠${NC}  Skipping Ansible validation (ansible-inventory not found)"
fi

# Display summary
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    Summary                                   ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Inventory file: ${INVENTORY_FILE}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. View inventory:"
echo -e "     cat ${INVENTORY_FILE}"
echo ""
echo -e "  2. Test connectivity:"
echo -e "     cd ${ANSIBLE_DIR}"
echo -e "     ansible all -i inventory/terraform.yml -m ping"
echo ""
echo -e "  3. Run playbook:"
echo -e "     ansible-playbook -i inventory/terraform.yml playbooks/playbook.yml"
echo ""

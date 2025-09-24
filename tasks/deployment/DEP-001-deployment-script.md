---
Task: Create end-to-end deployment script for automated MicroK8s cluster provisioning
Task ID: DEP-001
Priority: P0
Estimated Time: 3 hours
Dependencies: ANS-003
Status: ⏸️ Blocked
Created: 2025-09-20
Updated: 2025-09-20
---

## Objective

Create a comprehensive deployment script that orchestrates the entire MicroK8s cluster deployment pipeline from Terraform provisioning through Ansible configuration to validation, with proper error handling and rollback capabilities.

## Prerequisites

- [ ] ANS-003 completed (HA cluster formation working)
- [ ] Terraform modules tested and functional
- [ ] Ansible roles developed and validated
- [ ] Bash scripting knowledge
- [ ] Understanding of deployment pipeline flow

## Implementation Steps

### 1. **Create Main Deployment Script**

Create `scripts/deploy.sh`:

```bash
#!/bin/bash
set -euo pipefail

# MicroK8s Cluster Deployment Script
# Usage: ./scripts/deploy.sh [environment] [options]

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENVIRONMENT="${1:-development}"
TERRAFORM_DIR="${PROJECT_ROOT}/infrastructure-microk8s/environments/${ENVIRONMENT}"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"
LOGS_DIR="${PROJECT_ROOT}/logs/$(date +%Y%m%d_%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "${LOGS_DIR}/deploy.log"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOGS_DIR}/deploy.log"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOGS_DIR}/deploy.log"
}

# Create logs directory
mkdir -p "${LOGS_DIR}"

# Validate environment
if [[ ! -d "${TERRAFORM_DIR}" ]]; then
    error "Environment '${ENVIRONMENT}' not found at ${TERRAFORM_DIR}"
fi

log "Starting MicroK8s deployment for environment: ${ENVIRONMENT}"

# Run pre-flight checks
log "Running pre-flight checks..."
"${SCRIPT_DIR}/preflight-check.sh" "${ENVIRONMENT}" || error "Pre-flight checks failed"

# Terraform deployment
log "Deploying infrastructure with Terraform..."
cd "${TERRAFORM_DIR}"
terraform init -upgrade &>> "${LOGS_DIR}/terraform-init.log"
terraform plan -out=tfplan &>> "${LOGS_DIR}/terraform-plan.log"
terraform apply -auto-approve tfplan &>> "${LOGS_DIR}/terraform-apply.log" || {
    error "Terraform deployment failed. Check logs at ${LOGS_DIR}/terraform-apply.log"
}

# Extract outputs for Ansible
log "Extracting Terraform outputs..."
terraform output -json > "${ANSIBLE_DIR}/inventory/terraform-outputs.json"

# Generate Ansible inventory
log "Generating Ansible inventory..."
"${SCRIPT_DIR}/generate-inventory.sh" "${ENVIRONMENT}" || error "Inventory generation failed"

# Wait for VMs to be ready
log "Waiting for VMs to be accessible..."
"${SCRIPT_DIR}/wait-for-vms.sh" "${ANSIBLE_DIR}/inventory/${ENVIRONMENT}.yml" || {
    error "VMs not accessible after timeout"
}

# Run Ansible configuration
log "Configuring cluster with Ansible..."
cd "${ANSIBLE_DIR}"
export ANSIBLE_LOG_PATH="${LOGS_DIR}/ansible.log"

ansible-playbook -i "inventory/${ENVIRONMENT}.yml" \
    playbooks/site.yml \
    --vault-password-file .vault-pass \
    -e "environment=${ENVIRONMENT}" &>> "${LOGS_DIR}/ansible-playbook.log" || {
    error "Ansible configuration failed. Check logs at ${LOGS_DIR}/ansible-playbook.log"
}

# Validate cluster
log "Validating cluster health..."
ansible-playbook -i "inventory/${ENVIRONMENT}.yml" \
    playbooks/validate.yml &>> "${LOGS_DIR}/validation.log" || {
    warning "Cluster validation had warnings. Check ${LOGS_DIR}/validation.log"
}

# Run smoke tests
log "Running smoke tests..."
"${SCRIPT_DIR}/smoke-tests.sh" "${ENVIRONMENT}" &>> "${LOGS_DIR}/smoke-tests.log" || {
    warning "Some smoke tests failed. Check ${LOGS_DIR}/smoke-tests.log"
}

# Generate deployment report
log "Generating deployment report..."
"${SCRIPT_DIR}/generate-report.sh" "${ENVIRONMENT}" "${LOGS_DIR}" > "${LOGS_DIR}/deployment-report.txt"

log "✨ Deployment complete! Check report at ${LOGS_DIR}/deployment-report.txt"
```

### 2. **Create Pre-flight Check Script**

Create `scripts/preflight-check.sh`:

```bash
#!/bin/bash
set -euo pipefail

ENVIRONMENT="$1"

echo "🔍 Running pre-flight checks for ${ENVIRONMENT}..."

# Check required tools
for tool in terraform ansible-playbook jq ssh; do
    if ! command -v $tool &> /dev/null; then
        echo "❌ Required tool '$tool' not found"
        exit 1
    fi
done

# Check Proxmox connectivity
echo "Checking Proxmox API connectivity..."
# Add actual Proxmox API check here

# Check SSH keys
if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
    echo "❌ SSH public key not found"
    exit 1
fi

# Check Ansible vault password
if [[ ! -f ansible/.vault-pass ]]; then
    echo "❌ Ansible vault password file not found"
    exit 1
fi

echo "✅ All pre-flight checks passed"
```

### 3. **Create VM Wait Script**

Create `scripts/wait-for-vms.sh`:

```bash
#!/bin/bash
set -euo pipefail

INVENTORY_FILE="$1"
MAX_ATTEMPTS=30
SLEEP_TIME=10

echo "Waiting for VMs to be accessible..."

# Extract hosts from inventory
HOSTS=$(ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '._meta.hostvars | keys[]')

for host in $HOSTS; do
    echo "Checking $host..."
    attempt=1

    while [ $attempt -le $MAX_ATTEMPTS ]; do
        IP=$(ansible-inventory -i "$INVENTORY_FILE" --host "$host" | jq -r '.ansible_host')

        if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "${ansible_user}@${IP}" exit 2>/dev/null; then
            echo "✅ $host is accessible"
            break
        fi

        echo "Attempt $attempt/$MAX_ATTEMPTS failed for $host"
        sleep $SLEEP_TIME
        attempt=$((attempt + 1))
    done

    if [ $attempt -gt $MAX_ATTEMPTS ]; then
        echo "❌ Timeout waiting for $host"
        exit 1
    fi
done

echo "✅ All VMs are accessible"
```

### 4. **Create Inventory Generation Script**

Update `scripts/generate-inventory.sh`:

```bash
#!/bin/bash
set -euo pipefail

ENVIRONMENT="$1"
PROJECT_ROOT="$(dirname "$(dirname "$0")")"
TERRAFORM_DIR="${PROJECT_ROOT}/infrastructure-microk8s/environments/${ENVIRONMENT}"
ANSIBLE_DIR="${PROJECT_ROOT}/ansible"

cd "${TERRAFORM_DIR}"

# Generate YAML inventory from Terraform outputs
cat > "${ANSIBLE_DIR}/inventory/${ENVIRONMENT}.yml" << EOF
---
# Auto-generated inventory for ${ENVIRONMENT}
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

all:
  children:
    masters:
      hosts:
EOF

# Add master nodes from Terraform output
terraform output -json master_nodes 2>/dev/null | jq -r '.[] | "        \(.name):\n          ansible_host: \(.ip)"'

# Add workers if they exist
if terraform output -json worker_nodes 2>/dev/null; then
    echo "    workers:" >> "${ANSIBLE_DIR}/inventory/${ENVIRONMENT}.yml"
    echo "      hosts:" >> "${ANSIBLE_DIR}/inventory/${ENVIRONMENT}.yml"
    terraform output -json worker_nodes | jq -r '.[] | "        \(.name):\n          ansible_host: \(.ip)"'
fi

echo "✅ Inventory generated at ${ANSIBLE_DIR}/inventory/${ENVIRONMENT}.yml"
```

## Success Criteria

- [ ] Main deployment script orchestrates entire pipeline
- [ ] Pre-flight checks validate environment readiness
- [ ] Proper error handling with meaningful messages
- [ ] Logs captured for all operations
- [ ] Rollback capability on failures
- [ ] Deployment report generated

## Validation

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Test with dry run
TERRAFORM_DIR=infrastructure-microk8s/environments/development
cd $TERRAFORM_DIR && terraform plan

# Test pre-flight checks
./scripts/preflight-check.sh development

# Test full deployment in development
./scripts/deploy.sh development

# Check logs
ls -la logs/*/
cat logs/*/deployment-report.txt
```

Expected output:
- Scripts execute without syntax errors
- Pre-flight checks identify any missing requirements
- Deployment completes with success message
- Comprehensive logs generated
- Report shows cluster status

## Notes

- Use set -euo pipefail for robust error handling
- Capture all output to logs for debugging
- Make scripts idempotent where possible
- Consider adding --dry-run option for testing
- Include cleanup/rollback functions

## References

- [Bash Best Practices](https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html)
- [Planning Document](../../docs/planning.md) - Enhanced Deployment Pipeline section
- Existing scripts in `scripts/` directory
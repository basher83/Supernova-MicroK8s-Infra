#!/bin/bash
# Generate Terraform documentation for all modules and environments

set -e

# Check if terraform-docs is available
if ! command -v terraform-docs >/dev/null 2>&1; then
    echo "ERROR: terraform-docs is required but not installed." >&2
    echo "Install it using: mise install terraform-docs" >&2
    exit 1
fi

# Change to the repository root
cd "$(git rev-parse --show-toplevel)"

echo "Generating Terraform documentation..."

# Generate docs for terraform directory
echo "Processing terraform directory..."
terraform-docs --config .terraform-docs.yml terraform/

echo "Documentation generation complete!"

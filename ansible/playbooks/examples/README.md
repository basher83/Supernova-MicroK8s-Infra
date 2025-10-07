# Ansible Playbook Examples

This directory contains example playbooks demonstrating various Ansible automation patterns and troubleshooting techniques used in the Andromeda orchestration project.

## Example Categories

### ✅ **Working Examples** (Functional in this Repository)

These playbooks are fully functional and can be run directly against this repository's infrastructure:

#### 🔐 Security & Secrets Management

- **`infisical-demo.yml`** - Demonstrates Infisical integration for secrets management with real project configuration
- **`infisical-test.yml`** - Testing patterns for Infisical lookup plugins with actual repository secrets

### 📚 **Pattern Demonstrations** (Reference Examples)

These playbooks demonstrate useful Ansible patterns and techniques but may require adaptation for your specific environment:

#### 🔧 Troubleshooting & Diagnostics

- **`connectivity-test-simple.yml`** - Basic connectivity testing patterns between hosts
- **`connectivity-test-advanced.yml`** - Comprehensive connectivity and service health check patterns
- **`quick-status.yml`** - Fast status overview patterns for infrastructure components
- **`smoke-test-vault.yml`** - Vault smoke testing patterns and validation techniques

## Usage

### Working Examples (✅ Functional)

The **working examples** can be run directly:

```bash
# Infisical integration examples (require INFISICAL_* environment variables)
ansible-playbook playbooks/examples/infisical-demo.yml
ansible-playbook playbooks/examples/infisical-test.yml
```

### Pattern Demonstrations (📚 Reference)

The **pattern demonstrations** serve as:

- **Reference implementations** for common automation patterns
- **Troubleshooting templates** for infrastructure issues
- **Learning resources** for Ansible best practices
- **Starting points** for custom automation development

These examples may need adaptation for your specific environment and infrastructure.

## Service Endpoints

Service endpoints are centrally defined in `inventory/environments/all/service-endpoints.yml` to avoid hardcoded IPs throughout the codebase. Examples use these centralized definitions:

- **Consul**: `{{ service_endpoints.consul.addr }}`
- **Nomad**: `{{ service_endpoints.nomad.addr }}`
- **Vault**: `{{ service_endpoints.vault.addr }}`

These can be overridden via environment variables:

- `CONSUL_HTTP_ADDR`
- `NOMAD_ADDR`
- `VAULT_ADDR`

## Contributing

When adding new examples, consider the category:

### For Working Examples (✅ Functional)

- Must be **fully functional** against this repository's infrastructure
- Include real configuration and secrets management
- Add to the "Working Examples" section
- Require proper environment setup (INFISICAL\_\* vars, etc.)

### For Pattern Demonstrations (📚 Reference)

- Focus on **reusable patterns** and techniques
- Use placeholder/example values, not real repository config
- Add to the "Pattern Demonstrations" section
- Include adaptation notes for different environments

### General Guidelines

- Include clear documentation in playbook comments
- Add appropriate tags for selective execution
- Follow the project's Ansible coding standards
- Update this README with categorization and brief description

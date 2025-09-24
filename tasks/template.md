---
Task: <Brief description - be specific>
Task ID: <[PREFIX]-XXX - CI/IaC/CONFIG/DOCS/TEST/SEC>
Priority: <P0|P1|P2 - P0=Critical, P1=Important, P2=Nice-to-have>
Estimated Time: <X hours - realistic estimate>
Dependencies: <Task IDs or "None" - explicit dependencies>
Status: <🔄 Ready|⏸️ Blocked|🚧 In Progress|✅ Complete|❌ Failed>
Created: <Run: date +"%Y-%m-%d" - actual date when creating task>
Updated: <Run: date +"%Y-%m-%d" - update when status changes>
---

## Objective

<Clear statement of what needs to be accomplished and why>

## Prerequisites

- [ ] Clean working directory (`git status`)
- [ ] Required tools installed (`mise doctor`)
- [ ] <Dependencies that must be completed>
- [ ] <Access or permissions needed>

## Implementation Steps

### 1. **<First major step>**

```bash
# Example commands for this step
cd /home/basher83/dev/Supernova-MicroK8s-Infra
<specific commands>
```

<Detailed instructions>

### 2. **<Second major step>**

```bash
# Example commands for this step
<specific commands>
```

<Detailed instructions>

### 3. **<Third major step>**

```bash
# Example commands for this step
<specific commands>
```

<Detailed instructions>

## Success Criteria

- [ ] <Measurable validation point>
- [ ] <Test condition that must pass>
- [ ] <Expected outcome>
- [ ] <Performance or quality metric>

## Validation

```bash
# Terraform validation
cd terraform
terraform fmt -recursive -check
terraform validate
mise run prod-validate

# Ansible validation
cd ansible
ansible-lint
ansible-playbook -i inventory/hosts.yml playbooks/playbook.yml --syntax-check

# Pre-commit validation
pre-commit run --all-files

# Full project validation
mise run full-check
```

Expected output:
- All validation commands exit with code 0
- No errors or warnings in linter output
- <Specific success indicators>

## Files to Modify

- [ ] `path/to/file1` - <Description of changes>
- [ ] `path/to/file2` - <Description of changes>

## Notes

- <Important considerations or warnings>
- <Potential risks or impacts>
- <Additional context or tips>

## References

- [Project README](../../README.md)
- [Terraform Docs](../../terraform/README.md)
- [Ansible Roles](../../ansible/roles/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [Proxmox Provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs)

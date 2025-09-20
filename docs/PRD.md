# MicroK8s Cluster Product Requirements Document (PRD)

## Executive Summary

This document outlines the requirements for deploying a production-ready MicroK8s Kubernetes cluster infrastructure across development, staging, and production environments using Terraform on Proxmox virtualization platform.

## Project Overview

### Purpose

Deploy a scalable, highly available MicroK8s Kubernetes cluster infrastructure that provides:

- Container orchestration for microservices applications
- Consistent environments across dev/staging/production
- Enterprise-grade networking and storage capabilities
- Automated provisioning and scaling

### Scope

- Initial deployment to development environment for testing
- Progressive rollout to staging and production
- Infrastructure as Code using existing Terraform Proxmox modules
- Automated cluster bootstrapping and configuration

## Technical Architecture

### Infrastructure Platform

- **Hypervisor**: Proxmox VE
- **Provisioning**: Terraform (existing Proxmox modules)
- **Configuration Management**: Cloud-init for initial setup
- **Operating System**: Ubuntu Server 22.04 LTS or later

### Cluster Architecture

#### Node Configuration (All Environments)

- **Cluster Size**: 3 nodes (multi-node HA configuration)
- **Auto-scaling**: Planned capability for horizontal scaling
- **Node Specifications**:
  - **vCPU**: 4 cores minimum (8 recommended for production)
  - **RAM**: 16GB minimum (32GB for production)
  - **Storage**: 100GB SSD per node
  - **Network**: Bridged networking with static IP assignment

#### Environment Specifications

##### Development Environment

- 3 nodes with minimum specifications
- Relaxed resource constraints for testing
- [TODO: Specific IP range for dev environment?]

##### Staging Environment

- 3 nodes matching production specifications
- Full feature parity with production
- [TODO: Specific IP range for staging?]

##### Production Environment

- 3 nodes with recommended specifications
- High availability configuration
- [TODO: Specific IP range for production?]
- [TODO: Backup node for maintenance scenarios?]

### Networking Stack

#### Core Components

1. **LoadBalancer**: MetalLB
   - Dedicated IP pool (10-20 IPs reserved)
   - [TODO: Specific IP ranges per environment?]
   - Layer 2 mode for simplicity in homelab setup

2. **Ingress Controller**: NGINX Ingress
   - HTTP/HTTPS routing
   - SSL termination
   - WebSocket support
   - [TODO: Rate limiting requirements?]

3. **TLS Management**: Cert-Manager
   - Automatic certificate provisioning
   - Let's Encrypt integration
   - [TODO: Production certificate provider (Let's Encrypt/internal CA)?]
   - Certificate renewal automation

4. **DNS Management**
   - [TODO: External-DNS integration or manual management?]
   - [TODO: Domain names for each environment?]
   - Service discovery configuration

#### Network Configuration

- **Pod Network CIDR**: [TODO: Default 10.1.0.0/16 or custom?]
- **Service CIDR**: [TODO: Default 10.152.183.0/24 or custom?]
- **MetalLB IP Pool**: [TODO: Specific ranges per environment]
- **Firewall Rules**:
  - Port 16443: Kubernetes API
  - Port 80/443: HTTP/HTTPS ingress
  - Port 10250-10255: Kubelet and other services
  - [TODO: Additional application-specific ports?]

### Storage Architecture

#### Primary Storage

- **Development**: hostpath-storage for persistent volumes
- **Staging/Production**:
  - [TODO: NFS server details if using shared storage?]
  - [TODO: Ceph configuration if using distributed storage?]
  - [TODO: Storage classes and retention policies?]

#### Backup Strategy

- [TODO: Backup frequency and retention?]
- [TODO: Backup storage location?]
- [TODO: Disaster recovery procedures?]

### MicroK8s Add-ons

#### Core Add-ons (All Environments)

- `dns`: CoreDNS for cluster DNS
- `hostpath-storage`: Local persistent storage
- `dashboard`: Kubernetes dashboard
- `metrics-server`: Resource metrics

#### Networking Add-ons

- `metallb`: LoadBalancer implementation
- `ingress`: NGINX ingress controller
- `cert-manager`: TLS certificate management

#### Optional Add-ons

- [TODO: Registry - Local container registry needed?]
- [TODO: Prometheus/Grafana for monitoring?]
- [TODO: Observability stack (ELK/Loki)?]
- [TODO: GPU support for ML workloads?]

## Use Cases and Workloads

### Primary Workloads

- [TODO: Microservices applications details?]
- [TODO: Stateful services (databases, message queues)?]
- [TODO: CI/CD pipeline components?]
- [TODO: Development/testing environments?]

### Integration Requirements

- [TODO: External services to integrate with?]
- [TODO: Authentication systems (LDAP/AD/OAuth)?]
- [TODO: Existing databases or storage systems?]
- [TODO: CI/CD platforms (Jenkins/GitLab/GitHub Actions)?]

## Security Requirements

### Access Control

- RBAC policies for role-based access
- [TODO: User roles and permissions matrix?]
- [TODO: Service account requirements?]

### Network Security

- Network policies for pod-to-pod communication
- [TODO: Ingress/egress rules for applications?]
- [TODO: VPN access requirements?]

### Secrets Management

- [TODO: External secrets management (Vault/Infisical)?]
- [TODO: Certificate rotation policies?]
- [TODO: Database credential management?]

## Operations and Maintenance

### Monitoring and Observability

- [TODO: Metrics collection (Prometheus)?]
- [TODO: Log aggregation (ELK/Loki)?]
- [TODO: Alerting rules and escalation?]
- [TODO: Dashboard requirements (Grafana)?]

### GitOps and CI/CD

- [TODO: ArgoCD or Flux for GitOps?]
- [TODO: Deployment strategies (blue-green/canary)?]
- [TODO: Image registry (local MicroK8s/Harbor/external)?]

### Maintenance Windows

- [TODO: Scheduled maintenance windows?]
- [TODO: Update/upgrade procedures?]
- [TODO: Node drain and maintenance procedures?]

## Implementation Phases

### Phase 1: Development Environment (Week 1-2)

1. Provision 3 VMs using Terraform on Proxmox
2. Install MicroK8s and form cluster
3. Configure MetalLB with IP pool
4. Deploy NGINX Ingress Controller
5. Setup Cert-Manager with staging Let's Encrypt
6. Validate basic workload deployment

### Phase 2: Core Services (Week 3-4)

1. Configure persistent storage solution
2. Implement RBAC policies
3. Setup monitoring stack
4. Deploy sample applications
5. Document operational procedures

### Phase 3: Staging Environment (Week 5-6)

1. Replicate dev setup to staging
2. Configure production-like settings
3. Load testing and validation
4. Security hardening
5. Backup and restore testing

### Phase 4: Production Deployment (Week 7-8)

1. Production environment provisioning
2. Migration of workloads
3. Production certificates and DNS
4. Monitoring and alerting setup
5. Documentation and handover

## Success Criteria

### Performance Metrics

- [TODO: API response time targets?]
- [TODO: Pod startup time requirements?]
- [TODO: Throughput requirements?]

### Availability Targets

- [TODO: Uptime SLA (99.9%/99.99%)?]
- [TODO: Recovery Time Objective (RTO)?]
- [TODO: Recovery Point Objective (RPO)?]

### Operational Metrics

- Successful automated deployments

## Checklist Template

How to use:

- Fill each placeholder (values in <angle brackets>) with your exact settings.
- Items marked [Proposed] are sensible defaults you can accept or replace.

### Environments

- Environment subnets (dev/stage/prod CIDRs): <dev CIDR> / <stage CIDR> / <prod CIDR> — Proposed: 192.168.10.0/24 / 192.168.20.0/24 / 192.168.30.0/24 [Proposed]
- Node IP assignment: <static via cloud-init | DHCP reservations> — Proposed: static per node via cloud-init [Proposed]
- Node sizing (dev/stage/prod): <vCPU, RAM, disk> — Proposed: dev 4 vCPU / 16 GB / 100 GB; stage 8 vCPU / 32 GB / 200 GB; prod 8 vCPU / 32 GB / 200 GB [Proposed]
- Maintenance capacity: <spare node | headroom policy> — Proposed: no spare; ≤70% utilization target; PDBs to tolerate 1 node drain [Proposed]
- Environment parity: <deviations from prod in dev/stage> — Proposed: dev may omit HA storage and strict policies; stage parity with prod [Proposed]

### Networking

- Pod CIDR: <CIDR> — Proposed: 10.1.0.0/16 (MicroK8s default) [Proposed]
- Service CIDR: <CIDR> — Proposed: 10.152.183.0/24 (MicroK8s default) [Proposed]
- MetalLB IP pools (per env): <dev range> / <stage range> / <prod range> — Proposed: 192.168.10.50-192.168.10.69 / 192.168.20.50-192.168.20.79 / 192.168.30.50-192.168.30.89 [Proposed]
- Ingress rate limiting: <req/s, burst, scope> — Proposed: dev off; stage 50 r/s, burst 100 per IP; prod 200 r/s, burst 400 per IP; return 429 [Proposed]
- TLS issuer: <LE staging | LE prod | Internal CA>, challenge: <HTTP-01 | DNS-01> — Proposed: dev/stage LE staging HTTP-01; prod LE prod DNS-01 (wildcard) [Proposed]
- DNS automation: <ExternalDNS provider | manual> — Proposed: ExternalDNS via Cloudflare (token with zone:edit) [Proposed]
- Domains: <dev domain> / <stage domain> / <prod domain> — Proposed: dev.example.com / stage.example.com / example.com [Proposed]
- Firewall allow-list: <host/edge ports to open> — Proposed: 16443, 80/443, 10250-10255 plus app/storage ports; deny NodePort from WAN [Proposed]

### Storage

- Primary backend (stage): <NFS | Ceph | Other> — Proposed: NFS (simple, RWX) [Proposed]
- Primary backend (prod): <NFS | Ceph | Other> — Proposed: Ceph (replica 3, failure domains by host), or hardened NFS + backups if Ceph unavailable [Proposed]
- NFS details: <server IPs, exports, mount opts> — Proposed: 192.168.30.10:/srv/nfs/k8s, nfs4, rw,noatime,hard,timeo=600 [Proposed]
- StorageClasses: <names, params, default, reclaimPolicy> — Proposed: sc-nfs (default non-prod, Delete), sc-ceph-rbd (default prod, Retain), sc-fast (SSD tier) [Proposed]
- Backup tool/scope: <Velero/Kasten/etc., scope> — Proposed: Velero + restic for namespaces, PVs, CRDs [Proposed]
- Backup cadence/retention: <RPO targets> — Proposed: daily (30d), weekly (12w), monthly (12m), offsite copy [Proposed]
- Backup target: <S3/MinIO/NFS/PBS> — Proposed: S3-compatible MinIO with SSE-KMS [Proposed]
- DR drills: <frequency, scenarios> — Proposed: quarterly restores of Tier-1 app to staging [Proposed]

### MicroK8s Add-ons

- Core: <dns, hostpath-storage, dashboard, metrics-server> — Proposed: enable all in dev; disable dashboard in prod or protect with SSO [Proposed]
- Networking: <metallb, ingress, cert-manager> — Proposed: enable all [Proposed]
- Registry: <MicroK8s registry | Harbor | External> — Proposed: dev MicroK8s registry; stage/prod Harbor with GC and RBAC [Proposed]
- Monitoring: <stack choice> — Proposed: kube-prometheus-stack (Prometheus, Alertmanager, Grafana) [Proposed]
- Logs: <Loki | ELK> — Proposed: Loki + Promtail; 14–30d retention by env [Proposed]
- GPU: <needed?> — Proposed: off by default; add tainted GPU node pool if needed [Proposed]

### Workloads

- Microservices list: <services, owners, tiers> — Proposed: define Tier-1 (customer-facing), Tier-2 (internal), Tier-3 (batch) [Proposed]
- Stateful services: <DBs/queues in-cluster or external, HA mode> — Proposed: prefer managed/external for prod; in-cluster for dev/test only [Proposed]
- CI/CD components: <runners/executors in cluster?> — Proposed: ephemeral K8s runners with namespace RBAC [Proposed]
- Dev/test namespaces: <naming, quotas, TTL> — Proposed: namespace per feature; resource quotas; TTL 14 days [Proposed]
- SLOs per tier: <p95 latency, error budgets> — Proposed: Tier-1 p95 <200 ms, 99.9% monthly SLO [Proposed]

### Integrations

- External services: <APIs, VPCs, VPNs> — Proposed: egress via NAT; restrict with egress policies [Proposed]
- AuthN/Z: <OIDC/LDAP/AD> — Proposed: OIDC for kubectl and dashboard; group-based RBAC [Proposed]
- Existing DB/storage: <endpoints, connectivity, secrets> — Proposed: access via private IPs/VPN; secrets via External Secrets [Proposed]
- CI/CD platform: <Jenkins/GitLab/GitHub Actions> — Proposed: GitHub Actions + ArgoCD GitOps [Proposed]

### Security

- RBAC matrix: <roles, groups, namespaces> — Proposed: cluster-admin (SRE), namespace-admin (team leads), developer read/write per namespace, read-only auditors [Proposed]
- Service accounts: <per app, scopes, rotation> — Proposed: per-deploy SA with least privilege; rotate annually [Proposed]
- Network policies: <default posture> — Proposed: default deny-all; explicit allow-lists; restricted egress [Proposed]
- VPN access: <who, how> — Proposed: WireGuard to admin subnet; SSO enforced [Proposed]
- Secrets management: <Vault/Infisical/KMS> — Proposed: External Secrets + Vault (KV v2), namespace isolation, KMS-backed [Proposed]
- Cert rotation: <period, alerts> — Proposed: renew ~60 days before expiry; alert at <15 days remaining [Proposed]
- Image policy: <scanning, admission, provenance> — Proposed: Trivy in CI; Kyverno/Gatekeeper admission; cosign signature verification; allow-listed registries [Proposed]
- Audit logging: <sink, retention> — Proposed: ship API/audit logs to Loki or SIEM; retain 90 days [Proposed]

### Operations

- Metrics: <exporters, intervals> — Proposed: node, kube-state, cAdvisor; 30s scrape [Proposed]
- Logs: <sources, labels, retention> — Proposed: app + infra logs with k8s labels; 14d dev, 30d prod [Proposed]
- Alerting: <severities, escalation> — Proposed: P1 page SRE; P2 notify; on-call rotation; quiet hours policy [Proposed]
- Dashboards: <list + owners> — Proposed: cluster health, app dashboards per team, SLOs; owners assigned [Proposed]
- GitOps: <ArgoCD/Flux, drift, sync> — Proposed: ArgoCD; auto-sync non-prod; manual approve prod; PR-only changes [Proposed]
- Deploy strategies: <blue/green | canary | rolling> — Proposed: canary via Argo Rollouts for Tier-1; rolling for others [Proposed]
- Registry strategy: <local/external, cache> — Proposed: Harbor as primary; pull-through cache to Docker Hub/ghcr.io [Proposed]
- Maintenance windows: <per env> — Proposed: dev ad-hoc; stage Tue 20:00 (1h); prod monthly Sun 22:00 (2h) [Proposed]
- Upgrades: <MicroK8s channel, cadence, rollback> — Proposed: 1.30/stable; stage first; prod 2 weeks later; snapshot + rollback plan [Proposed]
- Node drain: <PDBs, surge, SOP> — Proposed: PDBs for critical services; maxUnavailable 1; SOP documented [Proposed]
- Host patching: <OS updates, kernel> — Proposed: unattended security updates weekly; coordinated reboots [Proposed]

### Proxmox & Infra

- Hosts: <count, CPU/mem, failure domains> — Proposed: spread K8s nodes across distinct Proxmox hosts/storage [Proposed]
- Templates: <Ubuntu image, hardening, cloud-init> — Proposed: Ubuntu 22.04 LTS template, SSH keys, NTP, CIS baseline [Proposed]
- Storage (Proxmox): <LVM/ZFS/Ceph, disk layout> — Proposed: ZFS mirror for OS; VM disks on ZFS with snapshots; PBS for backups [Proposed]
- Networking: <bridge, VLAN IDs, MTU, IPv6> — Proposed: vmbr0 trunk; dev VLAN 110, stage 120, prod 130; MTU 1500; IPv6 disabled unless needed [Proposed]
- IPAM/ownership: <who allocates, process> — Proposed: SRE owns IPAM; change tickets required [Proposed]
- Capacity/quotas: <overcommit, headroom, namespace quotas> — Proposed: CPU 1.5x, mem 1.2x; 30% headroom; team quotas [Proposed]

### Implementation Phases

- Phase 1 (Dev) entry/exit: <prereqs, tests> — Proposed: exit when LB, ingress, TLS staging, sample app OK [Proposed]
- Phase 2 (Core) entry/exit: <storage, RBAC, monitoring> — Proposed: exit when SCs defaulted, RBAC applied, dashboards live, runbooks drafted [Proposed]
- Phase 3 (Staging) entry/exit: <prod-like config, load/security tests> — Proposed: exit when load test passes SLOs; backup/restore validated [Proposed]
- Phase 4 (Prod) entry/exit: <cutover, certs, DNS, alerts> — Proposed: exit when on-call green, dashboards healthy, docs handed over [Proposed]
- Risks/dependencies: <DNS delegation, IP ranges, storage readiness, CA> — Proposed: track as blockers per phase [Proposed]

### Success Criteria

- Performance: <p95 latency, pod start time, throughput> — Proposed: p95 <200 ms (Tier-1); pod cold start <20s; target RPS per service [Proposed]
- Availability: <SLA, RTO, RPO> — Proposed: Stage 99.9%; Prod 99.95%; RTO 1h (Tier-1); RPO 15m (Tier-1) [Proposed]
- Operational: <CI/CD success rate, MTTR, CFR> — Proposed: >98% pipeline success; MTTR <30m non-prod / <1h prod; change failure rate <10% [Proposed]

- Cluster auto-scaling functionality
- Backup and restore validation
- [TODO: Specific application metrics?]

## Risks and Mitigation

### Technical Risks

1. **Risk**: Network configuration complexity
   - **Mitigation**: Start with simple L2 MetalLB configuration

2. **Risk**: Storage performance bottlenecks
   - **Mitigation**: SSD storage and consider distributed storage for production

3. **Risk**: Certificate management failures
   - **Mitigation**: Staging certificates first, monitoring expiration

### Operational Risks

- [TODO: Team knowledge gaps?]
- [TODO: Dependency on external services?]
- [TODO: Budget constraints?]

## Dependencies

### External Dependencies

- Proxmox infrastructure availability
- Network connectivity and DNS
- [TODO: Internet access for package downloads?]
- [TODO: External certificate authorities?]

### Internal Dependencies

- Terraform modules maintenance
- [TODO: Application readiness?]
- [TODO: Team availability for deployment?]

## Budget and Resources

### Infrastructure Costs

- [TODO: VM resource allocation costs?]
- [TODO: Storage costs?]
- [TODO: Network/bandwidth costs?]

### Operational Costs

- [TODO: Monitoring/logging storage?]
- [TODO: Backup storage?]
- [TODO: Certificate costs (if using paid CA)?]

## Appendix

### Quick Start Commands

#### Installation Steps

```bash
# Update System and Install Snapd
sudo apt update && sudo apt upgrade -y
sudo apt install snapd -y

# Install MicroK8s
sudo snap install microk8s --classic --channel=1.33

# Add User to MicroK8s Group
sudo usermod -a -G microk8s $USER
sudo chown -R $USER ~/.kube
# Log out and back in or reboot

# Check Status
microk8s status --wait-ready

# Enable Core Add-ons
microk8s enable dns hostpath-storage metrics-server dashboard

# Enable Networking Stack
microk8s enable metallb:10.64.140.43-10.64.140.49  # Adjust IP range
microk8s enable ingress
microk8s enable cert-manager
```

### Resource Links

- [MicroK8s Documentation](https://microk8s.io/docs/getting-started)
- [Ubuntu MicroK8s Tutorial](https://ubuntu.com/tutorials/getting-started-with-microk8s)
- [MetalLB Configuration Guide](https://metallb.universe.tf/configuration/)
- [NGINX Ingress Documentation](https://kubernetes.github.io/ingress-nginx/)
- [Cert-Manager Documentation](https://cert-manager.io/docs/)

### Configuration Templates

- [TODO: Example MetalLB ConfigMap]
- [TODO: Example Ingress resource]
- [TODO: Example Certificate resource]
- [TODO: Example NetworkPolicy]

---
*Document Version: 1.0*
*Last Updated: [Current Date]*
*Status: Draft - Pending [TODO] Items*

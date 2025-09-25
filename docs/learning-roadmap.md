# Learning Journey: MicroK8s Homelab

This roadmap guides you through building and learning with your MicroK8s homelab cluster. Focus on hands-on learning rather than production deployment. Each phase builds on the previous one.

## Phase 1: Basic Cluster Setup (Week 1)

**Goal**: Get a working HA MicroK8s cluster running.

### Tasks

- [ ] Deploy 5 Ubuntu VMs on Proxmox (2 control plane + 3 workers)
- [ ] Install MicroK8s on all nodes
- [ ] Form HA cluster (2 master nodes + 3 worker nodes)
- [ ] Enable core addons: `dns`, `storage`, `ingress`
- [ ] Verify cluster health with `microk8s status`

### Learning Objectives

- Understand MicroK8s installation process
- Learn HA cluster formation
- Basic addon concepts (DNS, storage, ingress)

### Success Criteria

- `microk8s kubectl get nodes` shows all nodes ready
- `microk8s status` shows HA enabled
- Basic cluster networking works

## Phase 2: External Access & Services (Week 2)

**Goal**: Enable external access to cluster services.

### Tasks

- [ ] Configure MetalLB for load balancing (`microk8s enable metallb:192.168.1.200-220`)
- [ ] Set up cert-manager for TLS certificates
- [ ] Deploy Kubernetes dashboard
- [ ] Create sample service with external IP
- [ ] Test HTTPS access with self-signed certificates

### Learning Objectives

- Load balancer concepts in Kubernetes
- Certificate management automation
- Service exposure patterns
- Kubernetes dashboard usage

### Success Criteria

- External IPs assigned to services
- Dashboard accessible via browser
- HTTPS working with cert-manager

## Phase 3: Application Deployment (Week 3)

**Goal**: Deploy and manage real applications.

### Tasks

- [ ] Deploy sample application (nginx, wordpress, or simple web app)
- [ ] Configure ingress for external access
- [ ] Set up persistent storage for application data
- [ ] Test application scaling and updates
- [ ] Experiment with resource limits and requests

### Learning Objectives

- Application deployment patterns
- Ingress configuration
- Persistent volume usage
- Application lifecycle management

### Success Criteria

- Application accessible via ingress URL
- Data persists across pod restarts
- Application scales up/down successfully

## Phase 4: Advanced Operations & GitOps (Future)

**Goal**: Explore advanced cluster management.

### Tasks

- [ ] Try ArgoCD for GitOps deployments
- [ ] Consider Rancher for cluster management UI
- [ ] Set up monitoring (prometheus/grafana)
- [ ] Implement backup/restore procedures
- [ ] Experiment with network policies

### Learning Objectives

- GitOps workflows
- Cluster management tools
- Monitoring and observability
- Security policies and backups

### Success Criteria

- Applications deploy via GitOps
- Monitoring dashboards show cluster health
- Backup/restore procedures tested

## Learning Principles

### Start Small, Learn Big

- Each phase introduces 2-3 new concepts
- Build confidence before adding complexity
- Hands-on experience over theory

### Experiment Freely

- Break things and learn from failures
- Try different approaches
- Document what works/doesn't work

### Iterate and Improve

- Revisit earlier phases with new knowledge
- Optimize configurations as you learn
- Share discoveries with the community

## Resources

- **Setup Guide**: [setup-guide.md](setup-guide.md) - Detailed installation steps
- **Inspiration**: [inspiration.md](inspiration.md) - Alternative approaches and ideas
- **Standards**: [standards/ansible-standards.md](standards/ansible-standards.md) - Automation best practices

## Progress Tracking

Use this checklist to track your learning journey:

```
Phase 1: [ ] Basic Cluster
Phase 2: [ ] External Access
Phase 3: [ ] Applications
Phase 4: [ ] Advanced Ops
```

Remember: This is your homelab, your learning journey. Go at your own pace and explore what interests you most!

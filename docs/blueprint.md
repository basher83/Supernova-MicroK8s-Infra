
## MicroK8s-Apollo: Homelab K8s That Just Works

### 1⃣ Setup & HA Magic

* **Install MicroK8s on each Ubuntu node**:

  ```bash
  sudo snap install microk8s --classic
  ```

* **On the first node**, run:

  ```bash
  microk8s status --wait-ready
  microk8s add-node
  ```

* **Join additional nodes** using the generated `microk8s join ...` command—no `--worker` flag for HA controlplane. With three or more nodes, HA is turned on **automatically**. ([microk8s.io][1], [Jonathan Gazeley][2], [Medium][3])

* **Optional HA tuning** (v1.20+): assign failure domains in `/var/snap/microk8s/current/args/ha-conf`, then `microk8s.stop; microk8s.start`. ([microk8s.io][1])

* **Check HA status**:

  ```bash
  microk8s status
  ```

  You’ll see control plane voter/standby nodes and confirmation that HA is running. ([microk8s.io][1])

---

### 2⃣ Enable Add-Ons—Instant Value

Run one-liners to get core services up and running:

```bash
microk8s enable dns ingress metallb storage cert-manager dashboard
```

* `dns`: internal service naming
* `ingress`: NGINX controller
* `metallb:IP‑range`: L2 load balancer with IP pool you define
* `storage`: default hostpath storage class
* `cert‑manager`: automated TLS
* `dashboard`: Kubernetes UI (optional)
  ([Zesty][4], [Reddit][5], [microk8s.io][6], [Jamie Phillips][7])

**MetalLB setup example**:

* As part of addon: `microk8s enable metallb:192.168.1.200-220`
* Or via YAML `IPAddressPool` manifest referencing your subnet. ([Ben Brougher][8], [microk8s.io][6])

**Ingress linked to MetalLB**: create a LoadBalancer service to front the NGINX ingress controller—it automatically picks an IP from MetalLB’s pool. ([Kiran Joy][9], [microk8s.io][6])

---

### 3⃣ Extra Pro Tips

* **Minimal friction**: Snap-based install + add-ons = fast cluster spin-up. ([Zesty][4], [Virtualization Howto][10])
* **Low-touch maintenance**: HA cluster handles leader election (\~5s) and voter promotion (\~30s) transparently. ([microk8s.io][1])
* **Launch config automation**: Predefine add-ons and MetalLB args in YAML at `/var/snap/microk8s/common/.microk8s.yaml` for recreatable setups. ([Jamie Phillips][7])

---

### 4⃣ MicroK8s-Apollo Necklace—Straight Shooter Summary

| Component      | Purpose                                   | Notes                           |
| -------------- | ----------------------------------------- | ------------------------------- |
| MicroK8s snap  | Core K8s deployment                       | `install`, `status`, `add-node` |
| HA Feature     | Resilient control plane & datastore       | Auto-enabled at 3+ nodes        |
| Add-ons Bundle | DNS, Ingress, LB, storage, TLS, dashboard | `microk8s enable ...`           |
| MetalLB        | External L2 LoadBalancing                 | Simple IP pool management       |
| Launch config  | Automated multi-node setup                | Custom `.microk8s.yaml`         |

---

### Quick Start Workflow (your 5-minute launch):

1. **Prep 3 Ubuntu nodes**: install snap & MicroK8s
2. **Cluster them**: use `add-node` & join on 2nd/3rd nodes — HA activates
3. **Enable the essentials**: `microk8s enable dns ingress metallb storage cert-manager dashboard` (just add IP pool for MetalLB)
4. **Deploy a sample app**: `kubectl apply`, expose via Ingress, test external IP + TLS

---

[1]: https://microk8s.io/docs/high-availability?utm_source=chatgpt.com "High Availability (HA)"
[2]: https://jonathangazeley.com/2023/01/15/kubernetes-homelab-part-1-overview/?utm_source=chatgpt.com "Kubernetes Homelab Part 1: Overview"
[3]: https://mohitkr.com/setting-up-microk8s-on-ubuntu-for-home-lab-4ac12f3d939f?utm_source=chatgpt.com "Setting up MicroK8s on Ubuntu for home lab | by Mohit Kumar"
[4]: https://zesty.co/finops-academy/kubernetes/how-to-use-k8s-for-pet-projects-and-homelabs/?utm_source=chatgpt.com "How to use Kubernetes for Pet Projects and Homelabs - Zesty.co"
[5]: https://www.reddit.com/r/kubernetes/comments/11xgyli/k8s_homelab_how_to_expose_an_application_fqdn_in/?utm_source=chatgpt.com "How to expose an application FQDN in home conditions ..."
[6]: https://microk8s.io/docs/addon-metallb?utm_source=chatgpt.com "Addon: MetalLB"
[7]: https://phillipsj.net/posts/new-home-lab-part-2-microk8s/?utm_source=chatgpt.com "New Home Lab Part 2: MicroK8s - Jamie Phillips"
[8]: https://benbrougher.tech/posts/microk8s-ingress/?utm_source=chatgpt.com "Kubernetes Ingress with microk8s, MetalLB, and the NGINX ..."
[9]: https://kiranjoy.blog/2024/07/02/how-to-build-a-high-availability-kubernetes-home-lab-with-microk8s-and-ubuntu-server-day-1/?utm_source=chatgpt.com "How to Build a High Availability Kubernetes Home Lab with ..."
[10]: https://www.virtualizationhowto.com/2025/02/install-microk8s-ultimate-beginners-configuration-guide/?utm_source=chatgpt.com "Install Microk8s: Ultimate Beginners Configuration Guide"

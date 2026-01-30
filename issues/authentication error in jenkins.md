It has been quite the journey from an empty workspace to a fully functioning Pro-level pipeline! Here is the summary of the troubleshooting and the final resolution for your documentation.

---

# 🛠️ Troubleshooting Report: Jenkins to Kubernetes (WSL) Connection

## 1. The Problems

We encountered three main "blockers" that prevented the pipeline from deploying correctly:

### A. The "Empty Workspace"

* **Issue:** The Jenkins pipeline was failing with `path "./backend" not found`.
* **Cause:** The `Jenkinsfile` had `skipDefaultCheckout(true)` enabled, meaning Jenkins created the folder but never actually downloaded the code from the repository.

### B. The "Case Sensitivity" Trap

* **Issue:** Errors occurred even when paths existed.
* **Cause:** In the Linux environment (Jenkins container), `Jenkins` and `jenkins` or `Backend` and `backend` are distinct. The folder names on the disk did not match the strings in the script.

### C. The "Authentication Required" Loop

* **Issue:** `kubectl` returned an HTML login page instead of communicating with the cluster.
* **Cause:** `kubectl` was hitting `127.0.0.1`. Inside a container, `127.0.0.1` is the container itself (Jenkins), not your cluster. Jenkins responded with its own login page, confusing `kubectl`.

---

## 2. The "Pro Way" Fixes

### ✅ Fix 1: Restore the Workspace

We removed `skipDefaultCheckout(true)` and ensured the `Jenkinsfile` used the exact folder names found in the repository (lowercase `backend` and `frontend`).

### ✅ Fix 2: Internal Docker Networking

Instead of using unstable IP addresses, we linked the containers directly:

1. **Network Alignment:** Updated `start-jenkins.sh` to include `--network kind`, putting Jenkins on the same private network as the Kubernetes nodes.
2. **DNS Routing:** Updated `~/.kube/config` to point to `infra-health-control-plane` (the container name) instead of `127.0.0.1`.

### ✅ Fix 3: TLS Verification Bypass

Because the Kubernetes SSL certificate is issued for `localhost`, it rejects connections from the name `infra-health-control-plane`. We added the `--insecure-skip-tls-verify` flag to all `kubectl` commands to allow the secure internal connection.

---

## 3. Final Pipeline Architecture

| Stage | Action | Purpose |
| --- | --- | --- |
| **Checkout** | `checkout scm` | Pulls the latest code into the Jenkins workspace; |
| **Build** | `docker build` | Creates fresh images for Backend and Frontend; |
| **Load** | `kind load` | Pushes images directly into the Kind nodes (no Registry needed); |
| **Deploy** | `kubectl apply` | Updates the cluster state and restarts Pods; |

---

## 4. Final Commands to Remember

**To fix the config file (Run once in WSL):**

```bash
sed -i 's/server: https:\/\/127.0.0.1:[0-9]*/server: https:\/\/infra-health-control-plane:6443/g' ~/.kube/config

```

**To start Jenkins properly:**

```bash
docker run -d --name infra-health-jenkins --network kind ...

```

---

**Now that the pipeline is green, would you like to set up a "Cleanup" stage to remove old Docker images and save disk space in WSL?**
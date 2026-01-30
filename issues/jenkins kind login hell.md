This was a classic case of **Docker-in-Docker networking conflicts**; here is the breakdown of why it happened and how we systematically dismantled the "Login Loop Hell;"

# 🛠 Troubleshooting Report: The Jenkins-Kubernetes Login Loop

## 1. The Symptom

Every time the Jenkins Pipeline reached the `Deploy` stage, `kubectl` failed with a strange error:

> `failed to download openapi: <html>...Authentication required... url=/login`

Essentially, `kubectl` was trying to talk to the Kubernetes API, but instead, it was receiving the **Jenkins Login Page** HTML;

---

## 2. The Root Cause: "Networking Hall of Mirrors"

The Jenkins container and the Kind Kubernetes nodes were sharing a Docker network;

* **The Conflict:** Inside the Jenkins container, the hostname for the Kubernetes API (`infra-health-control-plane`) was incorrectly resolving to `127.0.0.1` (localhost);
* **The Loop:** Since Jenkins was listening on the same machine/local-route, `kubectl`’s request to the cluster was intercepted by the **Jenkins Web Server**;
* **The Result:** Jenkins saw an unauthorized request and redirected `kubectl` to the login page; `kubectl` didn't know how to handle HTML, so it crashed;

---

## 3. The Multi-Stage Fix

### Phase A: Bypassing Validation

We first added the `--validate=false` flag to the `kubectl apply` command; This stopped `kubectl` from trying to download the OpenAPI schema (the request that was getting redirected), but it still failed because it couldn't find the real API server;

### Phase B: Direct IP Injection

Instead of relying on the problematic hostname, we modified the `Jenkinsfile` to find the **real** internal Docker IP of the Kubernetes node dynamically;

**The Code Change:**

```bash
# We grabbed the actual internal IP of the Kind container
KIND_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' infra-health-control-plane)

# We forced kubectl to ignore the config file server and use this IP
kubectl --server="https://${KIND_IP}:6443" ...

```

### Phase C: Permission & Credential Injection

Once the connection was established, the cluster asked: *"Who are you?"* because the Jenkins container lacked the security keys; We updated the `run-jenkins.sh` script to:

1. **Copy** the host's `~/.kube/config` into the container;
2. **Fix Permissions** using `chown` so the `jenkins` user (not root) could read the keys;

---

## 4. Final Solution Architecture

The final working environment uses a **direct-connect** strategy:

| Component | Role | Fix Applied |
| --- | --- | --- |
| **Networking** | Docker Bridge | Jenkins joined to the `kind` network; |
| **Discovery** | `docker inspect` | Dynamic IP detection in the Pipeline; |
| **Auth** | `kubeconfig` | Forced file injection and `chown` in the startup script; |
| **Validation** | `kubectl` | Disabled client-side OpenAPI validation; |

---

## 5. Summary of Lessons Learned

* **Localhost is dangerous:** In Docker-in-Docker environments, `127.0.0.1` rarely points where you think it does;
* **Volumes aren't enough:** Mounting a directory with `:ro` (read-only) can cause permission denied errors for the Jenkins user even if the file exists;
* **Direct IP > Hostnames:** When DNS gets messy in dev environments, targeting the Container IP directly is the "nuclear option" that always works;

---

**Would you like me to create a separate README section for your project that explains how to maintain this networking setup;?**
📁 Documentation: The 503 & ConfigError Resolve
🛑 Problem 1: CreateContainerConfigError
Symptom: When running kubectl get pods, the frontend pod showed CreateContainerConfigError and refused to start;

🔍 The "Why"
The Frontend deployment.yaml was configured to expect a ConfigMap called frontend-config to provide environment variables (like VITE_API_BASE_URL). Because that ConfigMap didn't exist in the cluster, Kubernetes could not "assemble" the container;

✅ The Fix
We created the missing ConfigMap manually to get the pod running, but the permanent fix was moving to Relative Paths;

🛑 Problem 2: 503 Service Temporarily Unavailable
Symptom: The browser could reach the domain, but showed a white screen with a generic NGINX 503 error;

🔍 The "Why"
A 503 error in Kubernetes means the Ingress Controller (the gatekeeper) is working, but it can't find any "Healthy" pods behind it; Since the Frontend pod was stuck in the error above, there was no app to send the traffic to;

✅ The Fix
Once the CreateContainerConfigError was resolved and the pod reached 1/1 Running, the Ingress automatically found the "Endpoint" and the 503 disappeared;

🛑 Problem 3: 404 Not Found (Ingress Class)
Symptom: The browser showed a 404 error even though the Ingress was applied;

🔍 The "Why"
The Ingress resource was missing the ingressClassName: nginx property. Without this, the NGINX controller ignored the routing rules, essentially "locking the front door";

✅ The Fix
We added ingressClassName: nginx to the ingress.yaml metadata, telling the controller to take ownership of those routes;

🛠️ The Permanent "Gold Standard" Solution
Instead of managing complex ConfigMaps for local development, we simplified the architecture using Relative Routing;

1. Code Change
We updated the Frontend API calls to use a relative path instead of a full URL;

JavaScript
// From this:
const API_BASE = "http://infra-health.local/api"; 

// To this:
const API_BASE = "/api"; 
2. Infrastructure Change
By using the same Ingress to host both the Frontend (/) and the Backend (/api), the browser automatically knows that /api refers to infra-health.local/api; This eliminates the need for:

ConfigMaps for URLs;

Hardcoded IP addresses;

Environment variable injection at build time;
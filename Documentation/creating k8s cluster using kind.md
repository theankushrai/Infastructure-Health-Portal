check if following things are installed

✅ docker --version
✅ kubectl version --client
✅ kind version

create a cluster => kind create cluster --name infra-health
verfify cluster is running => kubectl get nodes
verify pods => kubectl get pods -A

create namespace =>kubectl create namespace infra-health
verify namespace exists => kubectl create namespace infra-health
set namespace as default => kubectl config set-context --current --namespace=infra-health

appply mongodb yaml from k8s/mongo =>kubectl apply -f k8s/mongo/
verify mongodb pod => kubectl get pods
verify mongodb service => kubectl get svc

load backend docker image into kind => kind load docker-image infra-health-backend:latest --name infra-health
apply backend manifests =>kubectl apply -f k8s/backend/
verify backend pods is running => kubectl get pods

load worker image => kind load docker-image infra-health-backend:latest --name infra-health
apply worker manifest => kubectl apply -f k8s/worker/
verify worker pods => kubectl get pods

build frontend image => docker build -t infra-health-frontend:latest frontend
load it into kind => kind load docker-image infra-health-frontend:latest --name infra-health
apply frontend deployment =>kubectl apply -f k8s/frontend/deployment.yaml
verify frontend pod => kubectl get pods
apply service => kubectl apply -f k8s/frontend/service.yaml
verify service => kubectl get svc

install ingress controller =>kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
wait unitll its ready => kubectl get pods -n ingress-nginx
apply ingress yaml =>kubectl apply -f k8s/ingress/ingress.yaml

## STEP 5️⃣ Add host entry (VERY IMPORTANT)

Your laptop must know where `infra-health.local` points.

Edit hosts file:

### Windows

```
C:\Windows\System32\drivers\etc\hosts
```

Add:

```
127.0.0.1 infra-health.local
```
---

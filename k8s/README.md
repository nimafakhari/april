# Kubernetes Deployment Guide

## Prerequisites
- Docker Desktop with Kubernetes enabled, OR
- Minikube installed (`minikube start`)
- `kubectl` command-line tool

## File Structure
```
k8s/
├── namespace.yml           # Create app-namespace
├── redis-deployment.yml    # Redis service and deployment
├── app-deployment.yml      # App service and deployment
```

## Step-by-Step Deployment

### 1. Create Namespace
```bash
kubectl apply -f k8s/namespace.yml
```

### 2. Build Docker Image (if using Docker Desktop K8s)
```bash
docker build -t new-app:latest .
```

**Note:** If using Minikube, build inside Minikube:
```bash
eval $(minikube docker-env)
docker build -t new-app:latest .
```

### 3. Deploy Redis
```bash
kubectl apply -f k8s/redis-deployment.yml -n app-namespace
```

### 4. Deploy App
```bash
kubectl apply -f k8s/app-deployment.yml -n app-namespace
```

### 5. Verify Deployments
```bash
kubectl get pods -n app-namespace
kubectl get svc -n app-namespace
```

## Access the Application

### Using Docker Desktop K8s:
```bash
kubectl port-forward svc/app 8000:8000 -n app-namespace
```
Then open: `http://localhost:8000`

### Using Minikube:
```bash
minikube service app -n app-namespace
```

## Useful Commands

**View logs:**
```bash
kubectl logs -f deployment/app -n app-namespace
kubectl logs -f deployment/redis -n app-namespace
```

**Describe pods:**
```bash
kubectl describe pod <pod-name> -n app-namespace
```

**Delete all resources:**
```bash
kubectl delete namespace app-namespace
```

## Files Explained

**namespace.yml:**
- Groups all resources under one namespace to organize and isolate them

**redis-deployment.yml:**
- **Service:** Exposes Redis on `redis:6379` (DNS name)
- **Deployment:** Runs 1 Redis pod with resource limits

**app-deployment.yml:**
- **Service:** Exposes app (LoadBalancer type on ports 8000, 8001)
- **Deployment:** Runs 1 app pod with environment variables pointing to Redis
- **imagePullPolicy: Never:** Uses local Docker image (don't pull from registry)

//However, I notice it built to Docker Desktop, not minikube. Let me verify and rebuild for minikube:

minikube -p minikube docker-env --shell powershell | Invoke-Expression; docker ps


//Terminating the existing pods - Deletes the currently running pod(s) for the app deployment
Creating new pod(s) - Kubernetes immediately creates replacement pods using the current deployment spec
Pulling the updated image - Since the pod spec specifies imagePullPolicy: IfNotPresent, the new pods will use the image from the Docker registry (in this case, the new-app:latest image we just built in minikube)
kubectl rollout restart deployment/app -n app-namespace

minikube addons enable metrics-server




how to add detach's option to command. i want to dashboard stay up?
XSCORP+Nima.Fakhari@DTMLT5CG4450M8K MINGW64 /c/temp/75000/new (v3)
$ nohup minikube dashboard >/dev/null 2>&1 &
[1] 3511


how to How can I increase the number of recurring pods in the app and republish them more quickly?
# Scale to 3 pods immediately
kubectl scale deployment app -n default --replicas=3

# Verify they're starting
kubectl get pods -n default | grep app



-----------------------------------------------------------
You only use those commands in different scenarios:

# Force quick redeploy of latest image
kubectl rollout restart deployment/app -n default

# Check rollout status
kubectl rollout status deployment/app -n default

# View rollout history
kubectl rollout history deployment/app -n default
-----------------------------------------------------------------
how to detach pod from terminal's in this command:kubectl port-forward -n default svc/app 8000:8000
$ kubectl port-forward -n default svc/app 8000:8000 &
[2] 3595
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000

------------------------------
from this i have created new branch its name is v3_test
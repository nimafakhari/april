# Kubernetes Ingress Setup for new-app

## What Changed

1. **app-deployment.yml** — Updated `app-service` from `LoadBalancer` to `ClusterIP`
   - Ingress now handles external traffic routing
   - More efficient and follows best practices

2. **ingress.yml** (new) — Created Ingress resource to route external HTTP traffic

---

## How to Use

### 1. Install Nginx Ingress Controller (if not already installed)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

Or using Helm:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install nginx-ingress ingress-nginx/ingress-nginx --values ingress-values.yaml
```

### 2. Update the Ingress Domain

Edit `ingress.yml` and replace `newapp.example.com` with your actual domain:

```yaml
rules:
  - host: yourdomain.com  # <- Change this
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: app-service
              port:
                number: 8000
```

### 3. Deploy Everything

```bash
# Deploy app and Redis
kubectl apply -f k8s/app-deployment.yml
kubectl apply -f k8s/redis-deployment.yml

# Deploy Ingress
kubectl apply -f k8s/ingress.yml

# Verify
kubectl get ingress
kubectl get svc
kubectl get pods
```

### 4. Test Access

Once the Ingress IP is assigned:

```bash
# Get Ingress IP
kubectl get ingress new-app-ingress

# Add to /etc/hosts on your machine (if not using real DNS)
# <IP_ADDRESS> yourdomain.com

# Access the app
curl http://yourdomain.com
# or
firefox http://yourdomain.com
```

---

## Ingress Routing Examples

### Example 1: Multiple paths to different services

```yaml
rules:
  - host: myapp.example.com
    http:
      paths:
        - path: /app
          pathType: Prefix
          backend:
            service:
              name: app-service
              port:
                number: 8000
        - path: /api
          pathType: Prefix
          backend:
            service:
              name: api-service
              port:
                number: 5000
```

### Example 2: Multiple domains

```yaml
rules:
  - host: app.example.com
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: app-service
              port:
                number: 8000
  - host: api.example.com
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: api-service
              port:
                number: 5000
```

### Example 3: HTTPS with TLS

```yaml
spec:
  tls:
    - hosts:
        - myapp.example.com
      secretName: myapp-tls
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app-service
                port:
                  number: 8000
```

---

## Common Issues & Fixes

| Problem | Solution |
|---------|----------|
| `kubectl get ingress` shows pending IP | Install Ingress controller or wait for LoadBalancer IP |
| Connection refused | Check if pods are running: `kubectl get pods` |
| 502 Bad Gateway | Service port doesn't match deployment container port |
| 404 Not Found | Path routing is wrong—check `pathType` and `path` values |

---

## Next Steps

1. Test with `curl` from a pod: `kubectl run test --image=nicolaka/netshoot -it -- bash`
2. Monitor traffic: `kubectl logs deployment/new-app`
3. Add more paths/services as needed
4. Set up HTTPS with cert-manager for production


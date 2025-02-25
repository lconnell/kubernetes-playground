# Description
A playground for learning Kubernetes, ArgoCD and GitOps

There are two environments, `dev` and `prod`. I am using Kustomize to manage the manifests for both environments. Each environment is configured to reuse the same base but offer environment specific changes. This keeps the manifests DRY and easier to maintain.

# GitHub Action
A GitHub Action to validate Kubernetes manifests is triggered when submitting a pull request.

# Git Hooks
A Git pre-commit hook to validate Kubernetes manifests is used to prevent invalid manifests from being committed.

# ArgoCD
ArgoCD is used to manage the deployment of the manifests. See [README](argocd/README.md) for additional details.
``` bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

# API
The API is a simple Nginx server that is configured to use a custom Nginx configuration file.
``` bash
kubectl port-forward svc/api-dev 8081:80 -n development
```

# Database
The database is a PostgreSQL instance that is configured to use a custom PostgreSQL configuration file.
``` bash
kubectl port-forward svc/database-dev 5432:5432 -n development
```

# Admission Controller
Todo

# Troubleshooting
Test connectivity to the database from a pod in the development namespace.
``` bash
kubectl run -it --rm busybox -n development --image=busybox --restart=Never -- nc -zv db-dev 5432
```


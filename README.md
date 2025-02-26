### Build and Apply

```bash
kustomize build dev | kubectl apply -f -
kustomize build prd | kubectl apply -f -
```

### Verify

```bash
kubectl get all -n development
kubectl get all -n production
```

### Delete

```bash
kustomize build dev | kubectl delete -f -
kustomize build prd | kubectl delete -f -
```
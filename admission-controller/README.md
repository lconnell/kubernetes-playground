### Kubernetes Configuration
To integrate this with Kubernetes, you’d need to deploy it as a service and register it as a webhook. Here’s a basic setup (you’d need to run this after deploying the webhook):

### Notes:
- Replace <base64-encoded-ca-cert> with the CA certificate encoded in base64 for secure communication.
- Deploy the webhook pod with a proper TLS setup (certificates) in a production environment, as Kubernetes requires HTTPS for webhooks.

### Deployment to Kubernetes
- Deploy the Docker image to a registry (e.g., Docker Hub).
- Create a Kubernetes deployment for the webhook.
- Apply the service and webhook configurations with proper TLS certificates.

### Full Deployment

Below is a Kubernetes Deployment configuration for the webhook server you created earlier. This deployment will run the webhook service in your Kubernetes cluster, assuming you've built and pushed the Docker image to a container registry (e.g., Docker Hub, GCR, etc.). I'll include comments to explain each part.

#### Explanation:
Metadata:
- name: Names the deployment webhook-deployment.
- namespace: Uses default for simplicity. Change if deploying to a different namespace.
- labels: Ensures the deployment is identifiable and matches the service selector.

Spec:
- replicas: Set to 1 for a single instance. Increase for high availability.
- selector: Matches pods with the label app: webhook.
Template:
- Pod Labels: Matches the deployment's selector and service.
Containers:
- image: Replace your-registry/webhook:latest with the actual image path (e.g., docker.io/username/webhook:latest).
- ports: Exposes port 8000, where FastAPI runs.
- livenessProbe and readinessProbe: Uses the /health endpoint to check the container's health.
- resources: Sets modest CPU and memory requests/limits; adjust based on your needs.
- env: Ensures logs are unbuffered for real-time visibility.

#### Image Pull Secrets (Optional):
Uncomment and configure imagePullSecrets if your image is in a private registry.

#### Prerequisites:
Docker Image: Build and push your Docker image to a registry:
```bash
docker build -t your-registry/webhook:latest .
docker push your-registry/webhook:latest
```
TLS Certificates: For production, you'll need to configure TLS (HTTPS) since Kubernetes webhooks require secure communication. This involves mounting certificates into the container and adjusting the FastAPI server to use them (e.g., with uvicorn and SSL options). For simplicity, this example assumes HTTP for local testing.

#### Applying the Deployment
Apply it to your cluster:
```bash
kubectl apply -f webhook-deployment.yaml
```

#### Full Integration with Webhook
To fully integrate this with the webhook configurations from the previous response:
- Service: Already provided (webhook-service.yaml).
- ValidatingWebhookConfiguration: Already provided (validating-webhook.yaml).
- MutatingWebhookConfiguration: Already provided (mutating-webhook.yaml).

#### Apply all configurations:
```bash
kubectl apply -f webhook-deployment.yaml
kubectl apply -f webhook-service.yaml
kubectl apply -f validating-webhook.yaml
kubectl apply -f mutating-webhook.yaml
```

#### Additional Notes:
TLS Setup: In production, add a sidecar (like nginx) or modify the container to serve HTTPS by mounting certificates and configuring uvicorn with SSL:
```bash
uvicorn webhook:app --host 0.0.0.0 --port 8000 --ssl-keyfile=/path/to/key.pem --ssl-certfile=/path/to/cert.pem
```

#### Update the Dockerfile and Deployment accordingly.

- RBAC: Ensure the webhook service account has permissions to interact with the Kubernetes API if needed (usually minimal for webhooks).

- Scaling: For high availability, increase replicas and ensure your webhook logic is stateless or properly synchronized.

This deployment sets up the webhook server as a single pod, ready to handle validation and mutation requests once paired with the service and webhook configurations.

### Admission Controller

An admission controller is a piece of code that intercepts requests to the Kubernetes API server before the object is persisted, but after the request is authenticated and authorized. Admission controllers can be used to validate (accept/reject) or mutate (modify) resource requests. They are crucial for enforcing security policies, resource quotas, and ensuring consistency across your cluster. Common use cases include:

- Enforcing security contexts and pod security policies
- Automatically injecting sidecar containers
- Setting default resource limits
- Validating custom resource definitions
- Implementing organizational policies and compliance requirements

[Admission Controllers Docs](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)

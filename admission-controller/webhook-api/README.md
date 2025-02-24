Below is an example of how to create a Kubernetes validating and mutating admission webhook using Python with the FastAPI library, packaged as a Docker container and orchestrated with docker-compose. This webhook will validate and mutate pod creation requests, ensuring certain conditions are met or altering the pod spec as needed.

#### Webhook Logic:
- Validating: Check if a pod has a specific label (app.kubernetes.io/managed-by) and reject if missing.
- Mutating: Automatically add a label (webhook-injected: "true") to all pods being created.

#### FastAPI Server:
- Implement endpoints for validation and mutation.

#### Docker:
- Containerize the app.

#### docker-compose:
- Define the service to run the container.

#### Explanation:
- Validation: Checks if the pod has the app.kubernetes.io/managed-by label. If not, it rejects the request.
- Mutation: Adds a webhook-injected: true label to every pod using a JSONPatch operation.
- AdmissionReview: Kubernetes sends an AdmissionReview object, and the webhook must return one with allowed set and optional patches.

#### Build and Run:
```bash
docker-compose up --build
```

#### Test Locally:
Use curl or a tool like Postman to send an AdmissionReview request to http://localhost:8000/validate or /mutate.

#### Example validation request:
```json
{
  "apiVersion": "admission.k8s.io/v1",
  "kind": "AdmissionReview",
  "request": {
    "uid": "12345",
    "object": {
      "metadata": {
        "name": "test-pod"
      }
    }
  }
}

This should fail due to missing labels.
from fastapi import FastAPI, Request, HTTPException
from pydantic import BaseModel
import json
import base64
import logging

app = FastAPI()

# Logging setup
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Pydantic model for AdmissionReview request/response
class AdmissionReview(BaseModel):
    uid: str
    request: dict
    kind: dict
    apiVersion: str

# Helper function to create an admission response
def create_admission_response(uid, allowed, message=None, patch=None):
    response = {
        "apiVersion": "admission.k8s.io/v1",
        "kind": "AdmissionReview",
        "response": {
            "uid": uid,
            "allowed": allowed
        }
    }
    if message:
        response["response"]["status"] = {"message": message}
    if patch:
        patch_encoded = base64.b64encode(json.dumps(patch).encode()).decode()
        response["response"]["patchType"] = "JSONPatch"
        response["response"]["patch"] = patch_encoded
    return response

# Validating Webhook
@app.post("/validate")
async def validate_pod(request: Request):
    body = await request.json()
    logger.info("Received validation request: %s", body)
    
    admission_review = AdmissionReview(**body)
    uid = admission_review.uid
    pod = admission_review.request.get("object", {})

    # Validation logic: Check for required label
    labels = pod.get("metadata", {}).get("labels", {})
    if "app.kubernetes.io/managed-by" not in labels:
        return create_admission_response(
            uid=uid,
            allowed=False,
            message="Pod must have label 'app.kubernetes.io/managed-by'"
        )
    
    return create_admission_response(uid=uid, allowed=True)

# Mutating Webhook
@app.post("/mutate")
async def mutate_pod(request: Request):
    body = await request.json()
    logger.info("Received mutation request: %s", body)
    
    admission_review = AdmissionReview(**body)
    uid = admission_review.uid
    pod = admission_review.request.get("object", {})

    # Mutation logic: Add a label if not present
    patch = []
    if "labels" not in pod.get("metadata", {}):
        patch.append({"op": "add", "path": "/metadata/labels", "value": {}})
    patch.append({
        "op": "add",
        "path": "/metadata/labels/webhook-injected",
        "value": "true"
    })

    return create_admission_response(uid=uid, allowed=True, patch=patch)

# Health check endpoint
@app.get("/health")
async def health_check():
    return {"status": "healthy"}
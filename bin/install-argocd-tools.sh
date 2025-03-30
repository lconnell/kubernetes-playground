#!/bin/bash

# Script to install or uninstall ArgoCD in a Kubernetes cluster
# Usage: ./install-argocd-tools.sh [install|uninstall]

set -e  # Exit immediately if a command exits with a non-zero status

# Function to display usage information
usage() {
    echo "Usage: $0 [install|uninstall]"
    echo "  install   - Install ArgoCD in the cluster"
    echo "  uninstall - Remove ArgoCD from the cluster"
    exit 1
}

# Function to check if kubectl is available
check_kubectl_cli() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed or not in PATH"
        exit 1
    else
        echo "kubectl is available: $(kubectl version --client 2>/dev/null || echo 'version unknown')"
    fi
}

# Function to check if a namespace exists
check_namespace_exists() {
    kubectl get namespace "$1" &> /dev/null
}

# Function to check if ArgoCD CLI is available
check_argocd_cli() {
    if ! command -v argocd &> /dev/null; then
        echo "Warning: ArgoCD CLI is not installed or not in PATH"
        echo "You can install it later if needed:"
        echo "  - macOS: brew install argocd"
        echo "  - Linux: See instructions at https://argo-cd.readthedocs.io/en/stable/cli_installation/"
        echo ""
    else
        echo "argocd is available: $(argocd version --client 2>/dev/null || echo 'version unknown')"
    fi
}

# Function to install ArgoCD
install_argocd() {
    echo "Installing ArgoCD..."
    
    # Create namespace if it doesn't exist
    if ! check_namespace_exists "argocd"; then
        echo "Creating argocd namespace..."
        kubectl create namespace argocd
    else
        echo "Namespace argocd already exists"
    fi
    
    # Apply ArgoCD manifests
    echo "Applying ArgoCD manifests..."
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD server pod to be ready
    echo "Waiting for ArgoCD server to be ready (this may take a few minutes)..."
    kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
    if [ $? -ne 0 ]; then
        echo "Error: Timeout waiting for ArgoCD server to be ready"
        echo "Check pod status with: kubectl get pods -n argocd"
        exit 1
    fi
    
    # Get ArgoCD admin password
    echo -n "ArgoCD admin password: "
    kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
    
    echo ""
    echo "ArgoCD installed successfully!"
    echo "To access the ArgoCD UI, run: kubectl port-forward svc/argocd-server -n argocd 8080:443"
    echo "Then visit: https://localhost:8080 (accept the self-signed certificate)"
    echo ""
    echo "To login with the ArgoCD CLI:"
    echo "argocd login localhost:8080 --insecure --username admin --password <password>"
    echo "(Replace <password> with the password shown above)"
}

# Function to uninstall ArgoCD
uninstall_argocd() {
    echo "Uninstalling ArgoCD..."
    
    # Check if argocd namespace exists
    if check_namespace_exists "argocd"; then
        # Delete ArgoCD resources
        echo "Removing ArgoCD manifests..."
        kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --ignore-not-found
        
        # Delete the namespace
        echo "Deleting argocd namespace..."
        kubectl delete namespace argocd
        
        echo "ArgoCD uninstalled successfully!"
    else
        echo "ArgoCD namespace not found. Nothing to uninstall."
    fi
}

# Main script execution
check_kubectl_cli

# Check command line arguments
if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    install)
        check_argocd_cli
        install_argocd
        
        echo ""
        echo "ArgoCD installed successfully!"
        echo "To access ArgoCD UI: kubectl port-forward svc/argocd-server -n argocd 8080:443"
        ;;
    uninstall)
        uninstall_argocd
        
        echo ""
        echo "ArgoCD uninstalled successfully!"
        ;;
    *)
        echo "Error: Unknown command '$1'"
        usage
        ;;
esac

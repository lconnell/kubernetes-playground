#!/bin/bash

# Script to install or uninstall Flux, Flagger, and Headlamp in a Kubernetes cluster
# Usage: ./install-flux-tools.sh [install|uninstall]

set -euo pipefail  # Exit immediately if a command exits with a non-zero status

# Function to display usage information
usage() {
    echo "Usage: $0 [install|uninstall]"
    echo "  install   - Install Flux, Flagger, and Headlamp in the cluster"
    echo "  uninstall - Remove Flux, Flagger, and Headlamp from the cluster"
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

# Function to check if Flux CLI is available
check_flux_cli() {
    if ! command -v flux &> /dev/null; then
        echo "Warning: Flux CLI is not installed or not in PATH"
        echo "You can install it later if needed:"
        echo "  - macOS: brew install fluxcd/tap/flux"
        echo "  - Linux: curl -s https://fluxcd.io/install.sh | sudo bash"
        echo ""
    else
        echo "flux is available: $(flux version 2>/dev/null || echo 'version unknown')"
    fi
}

# Function to check if Helm is installed
check_helm_cli() {
    if ! command -v helm &> /dev/null; then
        echo "Error: helm is not installed or not in PATH"
        echo "Please install Helm: https://helm.sh/docs/intro/install/"
        exit 1
    else
        echo "helm is available: $(helm version 2>/dev/null || echo 'version unknown')"
    fi
}

# Function to install Flux
install_flux() {
    echo "Installing Flux controllers..."
    
    # Create flux-system namespace if it doesn't exist
    if ! check_namespace_exists "flux-system"; then
        echo "Creating flux-system namespace..."
        kubectl create namespace flux-system
    else
        echo "Namespace flux-system already exists"
    fi
    
    # Check Kubernetes cluster prerequisites
    echo "Checking prerequisites..."
    flux check --pre
    
    # Install Flux controllers
    echo "Installing Flux controllers..."
    flux install
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Flux controllers"
        echo "Check logs with: kubectl logs -n flux-system deployment/source-controller"
        exit 1
    fi
    
    echo "Flux controllers installed successfully!"
}

# Function to install Flagger
install_flagger() {
    echo "Installing Flagger..."
    
    # Add Flagger Helm repository
    echo "Adding Flagger Helm repository..."
    helm repo add flagger https://flagger.app
    
    # Update Helm repositories
    helm repo update
    
    # Install Flagger's Canary CRD
    echo "Installing Flagger's Canary CRD..."
    kubectl apply -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml
    
    # Install Flagger
    echo "Deploying Flagger..."
    helm upgrade -i flagger flagger/flagger \
        --namespace=flagger-system \
        --create-namespace \
        --set crd.create=false \
        --set meshProvider=kubernetes \
        --set metricsServer=http://prometheus.monitoring:9090
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Flagger"
        echo "Check pod status with: kubectl get pods -n flagger-system"
        exit 1
    fi
    
    echo "Flagger installed successfully!"
    echo "Note: For Flagger to work properly, you need to have Prometheus installed."
    echo "If you don't have Prometheus, install it in your cluster."
}

# Function to install Headlamp
install_headlamp() {
    echo "Installing Headlamp..."
    
    # Add Headlamp Helm repository
    echo "Adding Headlamp Helm repository..."
    helm repo add headlamp https://headlamp-k8s.github.io/headlamp/
    
    # Update Helm repositories
    helm repo update
    
    # Install Headlamp using Helm
    echo "Deploying Headlamp using Helm..."
    helm upgrade -i headlamp headlamp/headlamp \
        --namespace headlamp \
        --create-namespace \
        --set replicaCount=1 \
        --set service.type=ClusterIP \
        --set plugins.flux.enabled=true
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to install Headlamp"
        echo "Check pod status with: kubectl get pods -n headlamp"
        exit 1
    fi
    
    echo "Headlamp with Flux UI plugin installed successfully!"
    echo "To access Headlamp UI, run: kubectl port-forward -n headlamp svc/headlamp 8080:80"
    echo "Then visit: http://localhost:8080"
}

# Function to uninstall Flux
uninstall_flux() {
    echo "Uninstalling Flux..."
    
    # Check if flux-system namespace exists
    if check_namespace_exists "flux-system"; then
        # Uninstall Flux
        echo "Removing Flux controllers..."
        flux uninstall --silent
        
        echo "Flux uninstalled successfully!"
    else
        echo "Flux namespace not found. Nothing to uninstall."
    fi
}

# Function to uninstall Flagger
uninstall_flagger() {
    echo "Uninstalling Flagger..."
    
    # Check if flagger-system namespace exists
    if check_namespace_exists "flagger-system"; then
        # Uninstall Flagger
        echo "Removing Flagger..."
        helm uninstall flagger -n flagger-system
        
        # Delete Flagger's Canary CRD
        echo "Removing Flagger's Canary CRD..."
        kubectl delete -f https://raw.githubusercontent.com/fluxcd/flagger/main/artifacts/flagger/crd.yaml --ignore-not-found
        
        # Delete the namespace
        echo "Deleting flagger-system namespace..."
        kubectl delete namespace flagger-system
        
        echo "Flagger uninstalled successfully!"
    else
        echo "Flagger namespace not found. Nothing to uninstall."
    fi
}

# Function to uninstall Headlamp
uninstall_headlamp() {
    echo "Uninstalling Headlamp..."
    
    # Check if headlamp namespace exists
    if check_namespace_exists "headlamp"; then
        # Uninstall Headlamp using Helm
        echo "Removing Headlamp using Helm..."
        helm uninstall headlamp -n headlamp
        
        # Delete the namespace
        echo "Deleting headlamp namespace..."
        kubectl delete namespace headlamp
        
        echo "Headlamp uninstalled successfully!"
    else
        echo "Headlamp namespace not found. Nothing to uninstall."
    fi
}

# Main script execution
check_kubectl_cli
check_helm_cli
check_flux_cli

# Check command line arguments
if [ $# -ne 1 ]; then
    usage
fi

case "$1" in
    install)
        install_flux
        install_flagger
        install_headlamp
        ;;
    uninstall)
        uninstall_headlamp
        uninstall_flagger
        uninstall_flux
        ;;
    *)
        echo "Error: Unknown command '$1'"
        usage
        ;;
esac

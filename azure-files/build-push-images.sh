#!/bin/bash

#############################################
# Build and Push Docker Images to ACR
#############################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Get ACR details
log_info "Getting ACR information from Terraform..."
ACR_NAME=$(terraform output -raw acr_name 2>/dev/null || echo "")
ACR_SERVER=$(terraform output -raw acr_login_server 2>/dev/null || echo "")

if [ -z "$ACR_NAME" ] || [ -z "$ACR_SERVER" ]; then
    log_error "Failed to get ACR information. Make sure infrastructure is deployed."
    exit 1
fi

log_success "ACR Name: $ACR_NAME"
log_success "ACR Server: $ACR_SERVER"

# Login to ACR
log_info "Logging in to Azure Container Registry..."
az acr login --name "$ACR_NAME"
log_success "Logged in to ACR"

# Microservices to build
MICROSERVICES=("pdf-generator" "api-gateway" "data-processor")

# Check if source directories exist
log_info "Checking for microservice source directories..."
MISSING_DIRS=()
for service in "${MICROSERVICES[@]}"; do
    if [ ! -d "../$service" ]; then
        MISSING_DIRS+=("$service")
    fi
done

if [ ${#MISSING_DIRS[@]} -gt 0 ]; then
    log_warning "The following directories were not found:"
    for dir in "${MISSING_DIRS[@]}"; do
        echo "  - ../$dir"
    done
    log_warning "Please ensure your microservices are in the parent directory"
    echo ""
    log_info "Do you want to continue anyway? (yes/no)"
    read -r response
    if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        exit 1
    fi
fi

# Build and push each microservice
for service in "${MICROSERVICES[@]}"; do
    if [ ! -d "../$service" ]; then
        log_warning "Skipping $service (directory not found)"
        continue
    fi
    
    log_info "Building $service..."
    docker build -t "$service:latest" "../$service"
    log_success "Built $service"
    
    log_info "Tagging $service for ACR..."
    docker tag "$service:latest" "$ACR_SERVER/$service:latest"
    
    log_info "Pushing $service to ACR..."
    docker push "$ACR_SERVER/$service:latest"
    log_success "Pushed $service to ACR"
    
    echo ""
done

log_success "All images built and pushed successfully!"

# Update Kubernetes manifests
log_info "Updating Kubernetes manifests with ACR server..."
sed -i "s|<ACR_NAME>.azurecr.io|$ACR_SERVER|g" k8s-manifests/*.yaml
log_success "Kubernetes manifests updated"

echo ""
echo "✅ All Docker images are ready in ACR"
echo ""
echo "Available images:"
az acr repository list --name "$ACR_NAME" --output table

echo ""
echo "Next step: Deploy to Kubernetes"
echo "  kubectl apply -f k8s-manifests/"

#!/bin/bash

#############################################
# Configure Kubernetes Secrets for Azure
#############################################

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
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

log_info "Retrieving Azure resource information from Terraform..."

# Get Terraform outputs
COSMOSDB_CONN=$(terraform output -raw cosmosdb_connection_strings 2>/dev/null | jq -r '.[0]' 2>/dev/null || echo "")
STORAGE_CONN=$(terraform output -raw storage_account_primary_connection_string 2>/dev/null || echo "")
APPINSIGHTS_KEY=$(terraform output -raw application_insights_instrumentation_key 2>/dev/null || echo "")

if [ -z "$COSMOSDB_CONN" ] || [ -z "$STORAGE_CONN" ] || [ -z "$APPINSIGHTS_KEY" ]; then
    log_error "Failed to retrieve some Terraform outputs. Make sure infrastructure is deployed."
    exit 1
fi

log_success "Retrieved all necessary connection strings"

log_info "Creating/Updating Kubernetes secret 'azure-config'..."

kubectl create secret generic azure-config \
  --from-literal=COSMOSDB_CONNECTION_STRING="$COSMOSDB_CONN" \
  --from-literal=STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
  --from-literal=APPINSIGHTS_INSTRUMENTATION_KEY="$APPINSIGHTS_KEY" \
  --namespace=multicloud-dr \
  --dry-run=client -o yaml | kubectl apply -f -

log_success "Kubernetes secret 'azure-config' configured successfully"

log_info "Verifying secret..."
kubectl get secret azure-config -n multicloud-dr -o jsonpath='{.data}' | jq 'keys'

log_success "Secret verification complete"

echo ""
echo "✅ Kubernetes secrets are configured and ready to use"
echo ""
echo "Next step: Deploy the microservices"
echo "  kubectl apply -f k8s-manifests/"

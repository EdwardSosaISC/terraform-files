#!/bin/bash

#############################################
# Azure Infrastructure Deployment Script
# Multicloud Disaster Recovery Project
#############################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    log_success "Terraform found: $(terraform version | head -n1)"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        log_error "Azure CLI is not installed. Please install Azure CLI first."
        exit 1
    fi
    log_success "Azure CLI found: $(az version --query '\"azure-cli\"' -o tsv)"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_warning "kubectl is not installed. You'll need it later for AKS management."
    else
        log_success "kubectl found: $(kubectl version --client --short 2>/dev/null || echo 'installed')"
    fi
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_warning "Docker is not installed. You'll need it to build and push images."
    else
        log_success "Docker found: $(docker --version)"
    fi
}

# Azure login
azure_login() {
    log_info "Checking Azure authentication..."
    
    if ! az account show &> /dev/null; then
        log_warning "Not logged in to Azure. Initiating login..."
        az login
    fi
    
    SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
    
    log_success "Logged in to Azure"
    log_info "Subscription: $SUBSCRIPTION_NAME ($SUBSCRIPTION_ID)"
}

# Initialize Terraform
terraform_init() {
    log_info "Initializing Terraform..."
    terraform init
    log_success "Terraform initialized"
}

# Validate Terraform
terraform_validate() {
    log_info "Validating Terraform configuration..."
    terraform validate
    log_success "Terraform configuration is valid"
}

# Plan Terraform
terraform_plan() {
    log_info "Creating Terraform execution plan..."
    terraform plan -out=tfplan
    log_success "Terraform plan created"
    
    log_warning "Review the plan above. Do you want to continue? (yes/no)"
    read -r response
    if [[ ! "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        log_error "Deployment cancelled by user"
        exit 1
    fi
}

# Apply Terraform
terraform_apply() {
    log_info "Applying Terraform configuration..."
    log_warning "This will take approximately 15-20 minutes..."
    
    terraform apply tfplan
    log_success "Infrastructure deployed successfully!"
}

# Save outputs
save_outputs() {
    log_info "Saving Terraform outputs..."
    
    terraform output -json > outputs.json
    log_success "Outputs saved to outputs.json"
    
    # Save important values
    terraform output -raw vpn_gateway_public_ip > vpn_gateway_ip.txt 2>/dev/null || true
    terraform output -raw application_gateway_public_ip > app_gateway_ip.txt 2>/dev/null || true
    terraform output -raw acr_login_server > acr_server.txt 2>/dev/null || true
    
    log_success "Important IPs saved to individual files"
}

# Configure kubectl
configure_kubectl() {
    log_info "Configuring kubectl for AKS..."
    
    RESOURCE_GROUP=$(terraform output -raw resource_group_name)
    AKS_NAME=$(terraform output -raw aks_cluster_name)
    
    az aks get-credentials \
        --resource-group "$RESOURCE_GROUP" \
        --name "$AKS_NAME" \
        --overwrite-existing
    
    log_success "kubectl configured for AKS"
    
    log_info "Testing kubectl connection..."
    kubectl get nodes
    log_success "Successfully connected to AKS cluster"
}

# Display next steps
display_next_steps() {
    echo ""
    echo "=============================================="
    echo "  AZURE INFRASTRUCTURE DEPLOYED SUCCESSFULLY  "
    echo "=============================================="
    echo ""
    
    VPN_IP=$(cat vpn_gateway_ip.txt 2>/dev/null || echo "N/A")
    APPGW_IP=$(cat app_gateway_ip.txt 2>/dev/null || echo "N/A")
    ACR_SERVER=$(cat acr_server.txt 2>/dev/null || echo "N/A")
    
    echo "📋 Important Information:"
    echo "  - VPN Gateway IP: $VPN_IP"
    echo "  - Application Gateway IP: $APPGW_IP"
    echo "  - ACR Server: $ACR_SERVER"
    echo ""
    echo "📝 Next Steps:"
    echo ""
    echo "1️⃣  Configure AWS VPN Connection:"
    echo "   - Use VPN Gateway IP: $VPN_IP"
    echo "   - Configure Customer Gateway in AWS"
    echo "   - Create VPN Connection with shared key"
    echo ""
    echo "2️⃣  Build and Push Docker Images:"
    echo "   az acr login --name \$(terraform output -raw acr_name)"
    echo "   docker build -t pdf-generator:latest ./pdf-generator"
    echo "   docker tag pdf-generator:latest $ACR_SERVER/pdf-generator:latest"
    echo "   docker push $ACR_SERVER/pdf-generator:latest"
    echo "   # Repeat for api-gateway and data-processor"
    echo ""
    echo "3️⃣  Update Kubernetes Manifests:"
    echo "   sed -i 's|<ACR_NAME>.azurecr.io|$ACR_SERVER|g' k8s-manifests/*.yaml"
    echo ""
    echo "4️⃣  Configure Kubernetes Secrets:"
    echo "   ./scripts/configure-secrets.sh"
    echo ""
    echo "5️⃣  Deploy to AKS:"
    echo "   kubectl apply -f k8s-manifests/"
    echo ""
    echo "6️⃣  Test the Application:"
    echo "   curl http://$APPGW_IP/api/health"
    echo ""
    echo "📊 Monitor your infrastructure:"
    echo "   - Azure Portal: https://portal.azure.com"
    echo "   - kubectl get pods -n multicloud-dr"
    echo ""
    echo "=============================================="
}

# Main execution
main() {
    echo ""
    echo "=============================================="
    echo "  Azure Multicloud Infrastructure Deployment  "
    echo "=============================================="
    echo ""
    
    check_prerequisites
    azure_login
    terraform_init
    terraform_validate
    terraform_plan
    terraform_apply
    save_outputs
    
    log_info "Waiting 30 seconds for resources to stabilize..."
    sleep 30
    
    configure_kubectl
    display_next_steps
    
    log_success "Deployment completed successfully!"
}

# Run main function
main

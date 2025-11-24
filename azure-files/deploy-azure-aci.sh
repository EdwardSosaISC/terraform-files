#!/bin/bash
# Script de despliegue rápido para Azure Container Instances
# Uso: ./deploy-azure-aci.sh

set -e

echo "🚀 Azure Container Instances - Despliegue Multicloud DR"
echo "========================================================"
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "aci.tf" ]; then
    echo -e "${RED}❌ Error: No se encuentra aci.tf${NC}"
    echo "   Ejecuta este script desde el directorio azure-files/"
    exit 1
fi

# Paso 1: Verificar credenciales ACR
echo -e "${YELLOW}📋 Paso 1: Verificar configuración${NC}"
echo ""

if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}⚠️  No se encontró terraform.tfvars${NC}"
    echo "   Copiando desde ejemplo..."
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${RED}❌ ACCIÓN REQUERIDA:${NC}"
    echo "   Edita terraform.tfvars y completa:"
    echo "   - acr_admin_username"
    echo "   - acr_admin_password"
    echo ""
    echo "   Puedes obtener las credenciales con:"
    echo "   ${BLUE}az acr credential show --name multiclouddrnicolas${NC}"
    echo ""
    exit 1
fi

# Verificar si las variables están configuradas
if grep -q 'acr_admin_username = ""' terraform.tfvars; then
    echo -e "${RED}❌ ERROR: acr_admin_username no está configurado en terraform.tfvars${NC}"
    echo ""
    echo "   Obtén las credenciales con:"
    echo "   ${BLUE}az acr credential show --name multiclouddrnicolas${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Configuración encontrada${NC}"
echo ""

# Paso 2: Terraform Init
echo -e "${YELLOW}📦 Paso 2: Inicializar Terraform${NC}"
terraform init
echo -e "${GREEN}✅ Terraform inicializado${NC}"
echo ""

# Paso 3: Terraform Validate
echo -e "${YELLOW}🔍 Paso 3: Validar configuración${NC}"
terraform validate
echo -e "${GREEN}✅ Configuración válida${NC}"
echo ""

# Paso 4: Terraform Plan
echo -e "${YELLOW}📊 Paso 4: Ver plan de despliegue${NC}"
echo ""
terraform plan -out=tfplan
echo ""
echo -e "${BLUE}ℹ️  Plan guardado en tfplan${NC}"
echo ""

# Paso 5: Confirmar
echo -e "${YELLOW}❓ ¿Deseas aplicar los cambios? (yes/no)${NC}"
read -r response

if [ "$response" != "yes" ]; then
    echo -e "${RED}❌ Despliegue cancelado${NC}"
    exit 0
fi

# Paso 6: Terraform Apply
echo ""
echo -e "${YELLOW}🚀 Paso 5: Desplegando infraestructura...${NC}"
terraform apply tfplan
echo ""
echo -e "${GREEN}✅ ¡Despliegue completado!${NC}"
echo ""

# Paso 7: Mostrar outputs importantes
echo -e "${BLUE}📋 Información importante:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GATEWAY_IP=$(terraform output -raw application_gateway_public_ip 2>/dev/null || echo "N/A")
echo -e "${GREEN}🌐 Application Gateway IP:${NC} $GATEWAY_IP"

if [ "$GATEWAY_IP" != "N/A" ]; then
    echo ""
    echo -e "${BLUE}Endpoints disponibles:${NC}"
    echo "   Health Check: http://$GATEWAY_IP/health"
    echo "   API Gateway:  http://$GATEWAY_IP/api/"
    echo "   PDF Gen:      http://$GATEWAY_IP/pdf/"
    echo "   Data Proc:    http://$GATEWAY_IP/data/"
fi

echo ""
echo -e "${BLUE}Container Instances IPs:${NC}"
ACI_API=$(terraform output -raw aci_api_gateway_ip 2>/dev/null || echo "N/A")
ACI_PDF=$(terraform output -raw aci_pdf_generator_ip 2>/dev/null || echo "N/A")
ACI_DATA=$(terraform output -raw aci_data_processor_ip 2>/dev/null || echo "N/A")

echo "   API Gateway:   $ACI_API:8080"
echo "   PDF Generator: $ACI_PDF:8081"
echo "   Data Proc:     $ACI_DATA:8082"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Paso 8: Verificación automática
if [ "$GATEWAY_IP" != "N/A" ]; then
    echo -e "${YELLOW}🔍 Verificando endpoints...${NC}"
    echo ""
    
    echo -n "   Testing health endpoint... "
    if curl -s -f -m 10 "http://$GATEWAY_IP/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✅${NC}"
    else
        echo -e "${YELLOW}⏳ (puede tardar unos minutos en estar disponible)${NC}"
    fi
fi

echo ""
echo -e "${GREEN}🎉 ¡Despliegue exitoso!${NC}"
echo ""
echo "Para monitorear los contenedores:"
echo "  ${BLUE}az container list --resource-group rg-multicloud-dr-prod --output table${NC}"
echo ""
echo "Para ver logs:"
echo "  ${BLUE}az container logs --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway${NC}"
echo ""
echo "Para más información, consulta: ${BLUE}ACI_DEPLOYMENT.md${NC}"
echo ""

#!/bin/bash
# Script para aplicar terraform de forma incremental y crear recursos faltantes

set -e

echo "🔧 Aplicando Terraform de forma incremental..."
echo "=============================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m'

cd "$(dirname "$0")"

echo -e "${BLUE}Estado actual:${NC}"
echo "✅ Resource Group, VNet, VPN Gateway"
echo "✅ ACR con imágenes"
echo "❌ Subnet ACI, CosmosDB, Application Gateway, Container Instances"
echo ""

# Paso 1: Crear subnet ACI
echo -e "${YELLOW}Paso 1/5: Creando Subnet ACI...${NC}"
terraform apply \
  -target=azurerm_subnet.aci \
  -target=azurerm_network_security_group.aci \
  -target=azurerm_subnet_network_security_group_association.aci \
  -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Subnet ACI creado${NC}"
else
  echo -e "${RED}❌ Error creando subnet ACI${NC}"
  exit 1
fi
echo ""

# Paso 2: Crear CosmosDB (puede tardar 5-10 minutos)
echo -e "${YELLOW}Paso 2/5: Creando CosmosDB (esto tardará varios minutos)...${NC}"
terraform apply \
  -target=azurerm_cosmosdb_account.main \
  -target=azurerm_cosmosdb_mongo_database.main \
  -target=azurerm_cosmosdb_mongo_collection.main_data \
  -target=azurerm_cosmosdb_mongo_collection.pdf_metadata \
  -target=azurerm_private_endpoint.cosmosdb \
  -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ CosmosDB creado${NC}"
else
  echo -e "${RED}❌ Error creando CosmosDB${NC}"
  exit 1
fi
echo ""

# Paso 3: Crear Storage (si no existe)
echo -e "${YELLOW}Paso 3/5: Verificando Storage Account...${NC}"
terraform apply \
  -target=azurerm_storage_account.main \
  -target=azurerm_storage_container.pdfs \
  -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Storage Account verificado${NC}"
else
  echo -e "${RED}❌ Error con Storage Account${NC}"
  exit 1
fi
echo ""

# Paso 4: Crear Application Gateway
echo -e "${YELLOW}Paso 4/5: Creando Application Gateway...${NC}"
terraform apply \
  -target=azurerm_public_ip.appgw \
  -target=azurerm_application_gateway.main \
  -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Application Gateway creado${NC}"
else
  echo -e "${RED}❌ Error creando Application Gateway${NC}"
  exit 1
fi
echo ""

# Paso 5: Crear Container Instances
echo -e "${YELLOW}Paso 5/5: Creando Container Instances...${NC}"
terraform apply \
  -target=azurerm_log_analytics_workspace.aci \
  -target=azurerm_container_group.pdf_generator \
  -target=azurerm_container_group.api_gateway \
  -target=azurerm_container_group.data_processor \
  -auto-approve

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Container Instances creados${NC}"
else
  echo -e "${RED}❌ Error creando Container Instances${NC}"
  echo ""
  echo "Intentando ver el error específico..."
  terraform plan
  exit 1
fi
echo ""

# Verificación final
echo -e "${BLUE}Verificación final...${NC}"
terraform refresh > /dev/null 2>&1
echo ""
echo "=============================================="
echo -e "${GREEN}✅ Despliegue completado${NC}"
echo ""
echo "Outputs:"
terraform output
echo ""
echo "Verificar Container Instances:"
echo "  az container list --resource-group rg-multicloud-dr-prod-v2 -o table"
echo ""
echo "Verificar Application Gateway:"
echo "  APPGW_IP=\$(terraform output -raw application_gateway_public_ip)"
echo "  curl http://\$APPGW_IP/health"

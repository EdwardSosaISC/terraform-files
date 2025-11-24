#!/bin/bash
# Script master para solucionar problemas de ACI no creadas

set -e

echo "🔧 Solucionador de Problemas - Azure Container Instances"
echo "========================================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

RG_NAME="rg-multicloud-dr-prod-v2"
SUBSCRIPTION_ID="cf358c01-372e-49c2-bc60-72ab0fb8d928"

echo -e "${BLUE}Diagnóstico del problema:${NC}"
echo "Los outputs null indican que los Container Instances NO se crearon."
echo ""
echo -e "${YELLOW}Posibles causas:${NC}"
echo "1. Las imágenes no existen en el ACR"
echo "2. El subnet ACI no se creó correctamente"
echo "3. Errores durante terraform apply por problemas de red"
echo ""

# Verificar terraform state
echo -e "${BLUE}Estado actual de Terraform:${NC}"
echo ""

ACI_IN_STATE=$(terraform state list 2>/dev/null | grep -c "azurerm_container_group" || echo "0")
COSMOSDB_IN_STATE=$(terraform state list 2>/dev/null | grep -c "azurerm_cosmosdb_account" || echo "0")
SUBNET_IN_STATE=$(terraform state list 2>/dev/null | grep -c "azurerm_subnet.aci" || echo "0")

echo "Container Groups en state: $ACI_IN_STATE"
echo "CosmosDB en state: $COSMOSDB_IN_STATE"
echo "Subnet ACI en state: $SUBNET_IN_STATE"
echo ""

# Verificar recursos en Azure
echo -e "${BLUE}Recursos en Azure:${NC}"
ACI_COUNT=$(az container list --resource-group $RG_NAME --query "length([])" -o tsv 2>/dev/null || echo "0")
echo "Container Instances en Azure: $ACI_COUNT"
echo ""

# Opciones de solución
echo -e "${YELLOW}Selecciona una opción:${NC}"
echo ""
echo "1) Verificar imágenes en ACR (prerequisito)"
echo "2) Aplicar terraform y ver errores específicos"
echo "3) Crear recursos faltantes y luego terraform import"
echo "4) Recrear todo desde cero (destruir y crear)"
echo "5) Ver logs de Application Gateway para debug"
echo ""
read -p "Opción (1-5): " OPTION

case $OPTION in
  1)
    echo ""
    echo -e "${GREEN}Verificando ACR...${NC}"
    ACR_NAME="multiclouddrnicolas"
    
    echo "Repositorios en ACR:"
    az acr repository list --name $ACR_NAME -o table || {
      echo -e "${RED}❌ No se puede acceder al ACR${NC}"
      exit 1
    }
    
    echo ""
    echo "Para cada repositorio, tags disponibles:"
    for repo in $(az acr repository list --name $ACR_NAME -o tsv); do
      echo ""
      echo -e "${BLUE}$repo:${NC}"
      az acr repository show-tags --name $ACR_NAME --repository $repo -o table
    done
    
    echo ""
    echo -e "${YELLOW}Si las imágenes no existen, necesitas:${NC}"
    echo "  cd /ruta/a/microservicios"
    echo "  az acr login --name $ACR_NAME"
    echo ""
    echo "  # Para cada microservicio:"
    echo "  docker build -t \$ACR_NAME.azurecr.io/multicloud-dr/SERVICIO:latest ./SERVICIO"
    echo "  docker push \$ACR_NAME.azurecr.io/multicloud-dr/SERVICIO:latest"
    ;;
    
  2)
    echo ""
    echo -e "${GREEN}Ejecutando terraform apply...${NC}"
    echo ""
    
    # Ejecutar con nivel de debug
    TF_LOG=DEBUG terraform apply -auto-approve 2>&1 | tee terraform-apply.log
    
    echo ""
    echo "Logs guardados en: terraform-apply.log"
    echo ""
    echo "Verificando outputs..."
    terraform output
    ;;
    
  3)
    echo ""
    echo -e "${GREEN}Opción 3: Verificar y crear recursos faltantes${NC}"
    echo ""
    
    # Verificar subnet
    SUBNET_EXISTS=$(az network vnet subnet show \
      --resource-group $RG_NAME \
      --vnet-name multicloud-dr-v2-vnet \
      --name multicloud-dr-v2-aci-subnet \
      --query "id" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$SUBNET_EXISTS" ]; then
      echo -e "${RED}❌ Subnet ACI no existe. Creándola...${NC}"
      terraform apply -target=azurerm_subnet.aci -auto-approve
      echo -e "${GREEN}✅ Subnet creada${NC}"
    else
      echo -e "${GREEN}✅ Subnet ACI existe${NC}"
    fi
    
    # Verificar CosmosDB
    COSMOSDB_EXISTS=$(az cosmosdb show \
      --resource-group $RG_NAME \
      --name multicloud-dr-v2-cosmos-production \
      --query "id" -o tsv 2>/dev/null || echo "")
    
    if [ -z "$COSMOSDB_EXISTS" ]; then
      echo -e "${RED}❌ CosmosDB no existe. Creándola...${NC}"
      terraform apply -target=azurerm_cosmosdb_account.main -auto-approve
      echo -e "${GREEN}✅ CosmosDB creada (esto puede tardar varios minutos)${NC}"
    else
      echo -e "${GREEN}✅ CosmosDB existe${NC}"
    fi
    
    # Intentar crear ACIs
    echo ""
    echo -e "${YELLOW}Intentando crear Container Instances...${NC}"
    terraform apply -target=azurerm_container_group.pdf_generator \
                    -target=azurerm_container_group.api_gateway \
                    -target=azurerm_container_group.data_processor \
                    -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Recursos creados${NC}"
    echo ""
    echo "Verificando outputs:"
    terraform refresh
    terraform output
    ;;
    
  4)
    echo ""
    echo -e "${RED}⚠️  ADVERTENCIA: Esto destruirá y recreará recursos${NC}"
    read -p "¿Continuar? (yes/no): " CONFIRM
    
    if [ "$CONFIRM" != "yes" ]; then
      echo "Cancelado."
      exit 0
    fi
    
    echo ""
    echo -e "${YELLOW}Destruyendo Container Instances...${NC}"
    terraform destroy -target=azurerm_container_group.pdf_generator \
                      -target=azurerm_container_group.api_gateway \
                      -target=azurerm_container_group.data_processor \
                      -auto-approve || echo "No existían"
    
    echo ""
    echo -e "${GREEN}Creando Container Instances...${NC}"
    terraform apply -target=azurerm_container_group.pdf_generator \
                    -target=azurerm_container_group.api_gateway \
                    -target=azurerm_container_group.data_processor \
                    -auto-approve
    
    echo ""
    echo -e "${GREEN}✅ Recreado exitosamente${NC}"
    terraform output
    ;;
    
  5)
    echo ""
    echo -e "${GREEN}Verificando Application Gateway backends...${NC}"
    echo ""
    
    az network application-gateway show-backend-health \
      --resource-group $RG_NAME \
      --name multicloud-dr-v2-appgw \
      --output table
    
    echo ""
    echo "Ver logs del Application Gateway:"
    echo "  az monitor diagnostic-settings list --resource \$APPGW_ID"
    ;;
    
  *)
    echo -e "${RED}Opción inválida${NC}"
    exit 1
    ;;
esac

echo ""
echo "========================================================="
echo -e "${GREEN}✅ Proceso completado${NC}"

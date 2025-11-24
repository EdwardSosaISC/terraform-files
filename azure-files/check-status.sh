#!/bin/bash
# Script para verificar el estado actual de recursos Azure

set -e

echo "🔍 Verificando estado de recursos Azure..."
echo "==========================================="
echo ""

RG_NAME="rg-multicloud-dr-prod-v2"
ACR_NAME="multiclouddrnicolas"

# 1. Verificar Resource Group
echo "1️⃣ Resource Group:"
az group show --name $RG_NAME --query "{Name:name, Location:location, State:properties.provisioningState}" -o table 2>/dev/null || echo "❌ No existe"
echo ""

# 2. Verificar VNet y Subnets
echo "2️⃣ Virtual Network:"
az network vnet show --resource-group $RG_NAME --name multicloud-dr-v2-vnet --query "{Name:name, CIDR:addressSpace.addressPrefixes[0]}" -o table 2>/dev/null || echo "❌ No existe"
echo ""

echo "   Subnets:"
az network vnet subnet list --resource-group $RG_NAME --vnet-name multicloud-dr-v2-vnet --query "[].{Name:name, CIDR:addressPrefix, State:provisioningState}" -o table 2>/dev/null || echo "❌ No existen"
echo ""

# 3. Verificar Container Instances
echo "3️⃣ Container Instances:"
ACI_COUNT=$(az container list --resource-group $RG_NAME --query "length([])" -o tsv 2>/dev/null || echo "0")
if [ "$ACI_COUNT" = "0" ]; then
  echo "❌ No hay Container Instances creadas"
else
  az container list --resource-group $RG_NAME --query "[].{Name:name, IP:ipAddress.ip, State:instanceView.state}" -o table
fi
echo ""

# 4. Verificar ACR e Imágenes
echo "4️⃣ Azure Container Registry:"
az acr show --name $ACR_NAME --query "{Name:name, LoginServer:loginServer}" -o table 2>/dev/null || echo "❌ ACR no existe o no tienes acceso"
echo ""

echo "   Imágenes disponibles en ACR:"
az acr repository list --name $ACR_NAME -o table 2>/dev/null || echo "❌ No se puede listar repositorios"
echo ""

# 5. Verificar CosmosDB
echo "5️⃣ CosmosDB:"
az cosmosdb show --resource-group $RG_NAME --name multicloud-dr-v2-cosmos-production --query "{Name:name, Endpoint:documentEndpoint, State:provisioningState}" -o table 2>/dev/null || echo "❌ No existe"
echo ""

# 6. Verificar Application Gateway
echo "6️⃣ Application Gateway:"
az network application-gateway show --resource-group $RG_NAME --name multicloud-dr-v2-appgw --query "{Name:name, IP:frontendIPConfigurations[0].publicIPAddress.id, State:provisioningState}" -o table 2>/dev/null || echo "❌ No existe"
echo ""

# 7. Verificar VPN Gateway
echo "7️⃣ VPN Gateway:"
az network vnet-gateway show --resource-group $RG_NAME --name multicloud-dr-v2-vpn-gateway --query "{Name:name, IP:ipConfigurations[0].publicIPAddress.id, State:provisioningState}" -o table 2>/dev/null || echo "❌ No existe"
echo ""

# 8. Terraform State
echo "8️⃣ Terraform State:"
if [ -f "terraform.tfstate" ]; then
  echo "✅ terraform.tfstate existe"
  echo "Recursos en state:"
  terraform state list | grep -E "(container_group|cosmosdb_account)" || echo "❌ No hay ACI ni CosmosDB en state"
else
  echo "❌ terraform.tfstate no existe"
fi
echo ""

echo "==========================================="
echo "✅ Verificación completa"

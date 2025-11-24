#!/bin/bash
# Script para crear Container Instances manualmente y verificar imágenes

set -e

echo "🐳 Verificando ACR y creando Container Instances..."
echo "===================================================="
echo ""

RG_NAME="rg-multicloud-dr-prod-v2"
ACR_NAME="multiclouddrnicolas"
LOCATION="eastus"
VNET_NAME="multicloud-dr-v2-vnet"
SUBNET_NAME="multicloud-dr-v2-aci-subnet"

# 1. Verificar credenciales ACR
echo "1️⃣ Obteniendo credenciales ACR..."
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query "username" -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)
ACR_SERVER="${ACR_NAME}.azurecr.io"

echo "✅ ACR: $ACR_SERVER"
echo "✅ Usuario: $ACR_USERNAME"
echo ""

# 2. Listar imágenes disponibles
echo "2️⃣ Imágenes disponibles en ACR:"
REPOS=$(az acr repository list --name $ACR_NAME -o tsv 2>/dev/null || echo "")

if [ -z "$REPOS" ]; then
  echo "❌ No hay imágenes en el ACR"
  echo ""
  echo "⚠️  NECESITAS BUILD Y PUSH DE IMÁGENES:"
  echo "   cd /ruta/a/microservicios"
  echo "   docker build -t pdf-generator:latest ./pdf-generator"
  echo "   docker tag pdf-generator:latest $ACR_SERVER/multicloud-dr/pdf-generator:latest"
  echo "   docker push $ACR_SERVER/multicloud-dr/pdf-generator:latest"
  echo ""
  echo "   Repetir para api-gateway y data-processor"
  exit 1
else
  echo "$REPOS"
  echo ""
fi

# 3. Obtener subnet ID
echo "3️⃣ Obteniendo subnet ID..."
SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query "id" -o tsv 2>/dev/null || echo "")

if [ -z "$SUBNET_ID" ]; then
  echo "❌ Subnet ACI no existe. Ejecutar terraform apply primero."
  exit 1
fi
echo "✅ Subnet ID: $SUBNET_ID"
echo ""

# 4. Obtener valores de CosmosDB y Storage
echo "4️⃣ Obteniendo configuración de CosmosDB y Storage..."
COSMOSDB_ENDPOINT=$(az cosmosdb show \
  --resource-group $RG_NAME \
  --name multicloud-dr-v2-cosmos-production \
  --query "documentEndpoint" -o tsv 2>/dev/null || echo "")

COSMOSDB_KEY=$(az cosmosdb keys list \
  --resource-group $RG_NAME \
  --name multicloud-dr-v2-cosmos-production \
  --query "primaryMasterKey" -o tsv 2>/dev/null || echo "")

STORAGE_NAME="mcdrstgprod"
STORAGE_CONN=$(az storage account show-connection-string \
  --resource-group $RG_NAME \
  --name $STORAGE_NAME \
  --query "connectionString" -o tsv 2>/dev/null || echo "")

if [ -z "$COSMOSDB_ENDPOINT" ] || [ -z "$STORAGE_CONN" ]; then
  echo "❌ CosmosDB o Storage no existen. Ejecutar terraform apply primero."
  exit 1
fi

echo "✅ CosmosDB: $COSMOSDB_ENDPOINT"
echo "✅ Storage: $STORAGE_NAME"
echo ""

# 5. Preguntar si crear Container Instances
read -p "¿Crear Container Instances? (yes/no): " CREATE_ACI

if [ "$CREATE_ACI" != "yes" ]; then
  echo "Cancelado."
  exit 0
fi

# 6. Crear PDF Generator
echo ""
echo "5️⃣ Creando PDF Generator Container Instance..."
az container create \
  --resource-group $RG_NAME \
  --name multicloud-dr-v2-pdf-generator \
  --image $ACR_SERVER/multicloud-dr/pdf-generator:latest \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 1 \
  --memory 1.5 \
  --ip-address Private \
  --subnet $SUBNET_ID \
  --ports 8081 \
  --environment-variables \
    AZURE_REGION=$LOCATION \
    STORAGE_ACCOUNT_NAME=$STORAGE_NAME \
    COSMOSDB_ENDPOINT=$COSMOSDB_ENDPOINT \
    COSMOSDB_DATABASE=multicloud-dr-db \
    STORAGE_CONTAINER_NAME=pdfs \
    PYTHONUNBUFFERED=1 \
  --secure-environment-variables \
    COSMOSDB_KEY=$COSMOSDB_KEY \
    STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
  --os-type Linux \
  --restart-policy Always

echo "✅ PDF Generator creado"
echo ""

# 7. Crear API Gateway
echo "6️⃣ Creando API Gateway Container Instance..."
az container create \
  --resource-group $RG_NAME \
  --name multicloud-dr-v2-api-gateway \
  --image $ACR_SERVER/multicloud-dr/api-gateway:latest \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 1 \
  --memory 1.5 \
  --ip-address Private \
  --subnet $SUBNET_ID \
  --ports 8080 \
  --environment-variables \
    AZURE_REGION=$LOCATION \
    COSMOSDB_ENDPOINT=$COSMOSDB_ENDPOINT \
    COSMOSDB_DATABASE=multicloud-dr-db \
    PYTHONUNBUFFERED=1 \
  --secure-environment-variables \
    COSMOSDB_KEY=$COSMOSDB_KEY \
  --os-type Linux \
  --restart-policy Always

echo "✅ API Gateway creado"
echo ""

# 8. Crear Data Processor
echo "7️⃣ Creando Data Processor Container Instance..."
az container create \
  --resource-group $RG_NAME \
  --name multicloud-dr-v2-data-processor \
  --image $ACR_SERVER/multicloud-dr/data-processor:latest \
  --registry-username $ACR_USERNAME \
  --registry-password $ACR_PASSWORD \
  --cpu 1 \
  --memory 1.5 \
  --ip-address Private \
  --subnet $SUBNET_ID \
  --ports 8082 \
  --environment-variables \
    AZURE_REGION=$LOCATION \
    COSMOSDB_ENDPOINT=$COSMOSDB_ENDPOINT \
    COSMOSDB_DATABASE=multicloud-dr-db \
    PYTHONUNBUFFERED=1 \
  --secure-environment-variables \
    COSMOSDB_KEY=$COSMOSDB_KEY \
  --os-type Linux \
  --restart-policy Always

echo "✅ Data Processor creado"
echo ""

# 9. Verificar Container Instances
echo "8️⃣ Verificando Container Instances creadas:"
az container list --resource-group $RG_NAME --query "[].{Name:name, IP:ipAddress.ip, State:instanceView.state}" -o table
echo ""

echo "===================================================="
echo "✅ Container Instances creadas exitosamente"
echo ""
echo "Próximo paso:"
echo "  terraform import azurerm_container_group.pdf_generator /subscriptions/cf358c01-372e-49c2-bc60-72ab0fb8d928/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/multicloud-dr-v2-pdf-generator"
echo "  terraform import azurerm_container_group.api_gateway /subscriptions/cf358c01-372e-49c2-bc60-72ab0fb8d928/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/multicloud-dr-v2-api-gateway"
echo "  terraform import azurerm_container_group.data_processor /subscriptions/cf358c01-372e-49c2-bc60-72ab0fb8d928/resourceGroups/$RG_NAME/providers/Microsoft.ContainerInstance/containerGroups/multicloud-dr-v2-data-processor"

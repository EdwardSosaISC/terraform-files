# Azure Multicloud Infrastructure - README

## 📋 Descripción General

Esta infraestructura en Azure complementa la arquitectura AWS existente, creando un sistema multicloud tolerante a fallos con replicación de datos entre nubes.

## 🏗️ Arquitectura de Componentes Azure

### Servicios Principales:
- **AKS (Azure Kubernetes Service)**: Reemplaza ECS/Fargate para microservicios
- **CosmosDB**: Reemplaza DynamoDB con API MongoDB
- **Azure Blob Storage**: Reemplaza S3 para almacenamiento de archivos
- **Azure Data Factory**: Pipeline para replicar datos desde S3
- **Application Gateway**: Balanceador de carga (equivalente a ALB)
- **VPN Gateway**: Conectividad con AWS mediante IPSec

### Red:
- **VNet**: 10.20.0.0/16
- **Subnet AKS**: 10.20.1.0/24
- **Subnet Database**: 10.20.2.0/24
- **Subnet AppGW**: 10.20.3.0/24
- **Gateway Subnet**: 10.20.255.0/27

## 📦 Estructura del Proyecto

```
azure-files/
├── providers.tf          # Configuración de providers Azure
├── variables.tf          # Variables del proyecto
├── main.tf              # Recursos principales y locals
├── network.tf           # VNet, subnets, NSGs, VPN Gateway
├── aks.tf               # Azure Kubernetes Service
├── cosmosdb.tf          # Base de datos NoSQL
├── storage.tf           # Azure Blob Storage
├── datafactory.tf       # Pipeline S3 → Blob
├── appgateway.tf        # Application Gateway (Load Balancer)
├── monitoring.tf        # Azure Monitor, Log Analytics
├── outputs.tf           # Outputs de recursos creados
└── k8s-manifests/       # Manifiestos de Kubernetes
    ├── 00-namespace.yaml
    ├── 01-configmap-secret.yaml
    ├── 02-pdf-generator.yaml
    ├── 03-api-gateway.yaml
    └── 04-data-processor.yaml
```

## 🚀 Prerequisitos

### Software Necesario:
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform >= 1.0
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Docker (para build de imágenes)
sudo apt-get update
sudo apt-get install docker.io -y
```

### Autenticación Azure:
```bash
# Login en Azure
az login

# Verificar suscripción activa
az account show

# Configurar suscripción (si es necesario)
az account set --subscription "cf358c01-372e-49c2-bc60-72ab0fb8d928"
```

## 📝 Configuración Previa

### 1. Actualizar variables.tf

Edita `variables.tf` con tus valores:

```hcl
# Azure Credentials (ya configurados)
variable "azure_subscription_id" {
  default = "cf358c01-372e-49c2-bc60-72ab0fb8d928"
}

variable "azure_tenant_id" {
  default = "a1672a4e-def0-4aaf-bcf6-754ea59c5651"
}

# AWS VPN Configuration (después de desplegar AWS)
variable "aws_vpn_gateway_ip" {
  default = "X.X.X.X"  # IP pública del AWS VPN Gateway
}

# AWS S3 Credentials (para Data Factory)
variable "aws_access_key_id" {
  default = "AKIAXXXXXXXXXXXXX"
  sensitive = true
}

variable "aws_secret_access_key" {
  default = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  sensitive = true
}
```

### 2. Crear archivo terraform.tfvars (opcional)

```hcl
# terraform.tfvars
azure_location = "eastus"
environment = "production"
project_name = "multicloud-dr"
aks_node_count = 2
```

## 🔧 Despliegue Paso a Paso

### Fase 1: Inicializar Terraform

```bash
cd azure-files

# Inicializar providers
terraform init

# Validar configuración
terraform validate

# Ver plan de ejecución
terraform plan
```

### Fase 2: Crear Infraestructura Azure

```bash
# Aplicar configuración (esto tardará ~15-20 minutos)
terraform apply -auto-approve

# Guardar outputs importantes
terraform output -json > outputs.json
terraform output vpn_gateway_public_ip > vpn_ip.txt
```

### Fase 3: Configurar VPN AWS ↔ Azure

**En AWS (después de obtener la IP del VPN Gateway de Azure):**

1. Crear Customer Gateway apuntando a la IP de Azure
2. Crear VPN Connection con el shared key
3. Actualizar Route Tables para enrutar tráfico a Azure (10.20.0.0/16)

Ver guía completa en: `docs/vpn-configuration.md`

### Fase 4: Configurar kubectl para AKS

```bash
# Obtener credenciales de AKS
az aks get-credentials \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-aks

# Verificar conexión
kubectl get nodes
kubectl get namespaces
```

### Fase 5: Preparar Imágenes Docker

```bash
# Login en ACR
ACR_NAME=$(terraform output -raw acr_name)
az acr login --name $ACR_NAME

# Build y push de imágenes (desde directorio de microservicios)
ACR_SERVER=$(terraform output -raw acr_login_server)

# PDF Generator
docker build -t pdf-generator:latest ./pdf-generator
docker tag pdf-generator:latest $ACR_SERVER/pdf-generator:latest
docker push $ACR_SERVER/pdf-generator:latest

# API Gateway
docker build -t api-gateway:latest ./api-gateway
docker tag api-gateway:latest $ACR_SERVER/api-gateway:latest
docker push $ACR_SERVER/api-gateway:latest

# Data Processor
docker build -t data-processor:latest ./data-processor
docker tag data-processor:latest $ACR_SERVER/data-processor:latest
docker push $ACR_SERVER/data-processor:latest
```

### Fase 6: Configurar Secrets de Kubernetes

```bash
# Obtener valores de Terraform
COSMOSDB_CONN=$(terraform output -raw cosmosdb_connection_strings | jq -r '.[0]')
STORAGE_CONN=$(terraform output -raw storage_account_primary_connection_string)
APPINSIGHTS_KEY=$(terraform output -raw application_insights_instrumentation_key)

# Actualizar secrets
kubectl create secret generic azure-config \
  --from-literal=COSMOSDB_CONNECTION_STRING="$COSMOSDB_CONN" \
  --from-literal=STORAGE_CONNECTION_STRING="$STORAGE_CONN" \
  --from-literal=APPINSIGHTS_INSTRUMENTATION_KEY="$APPINSIGHTS_KEY" \
  --namespace=multicloud-dr \
  --dry-run=client -o yaml | kubectl apply -f -
```

### Fase 7: Actualizar Manifiestos K8s

```bash
# Reemplazar <ACR_NAME> en los manifiestos
ACR_SERVER=$(terraform output -raw acr_login_server)

sed -i "s|<ACR_NAME>.azurecr.io|$ACR_SERVER|g" k8s-manifests/*.yaml
```

### Fase 8: Desplegar en AKS

```bash
# Aplicar todos los manifiestos
kubectl apply -f k8s-manifests/

# Verificar deployments
kubectl get deployments -n multicloud-dr
kubectl get pods -n multicloud-dr
kubectl get services -n multicloud-dr
kubectl get hpa -n multicloud-dr
```

### Fase 9: Verificar Application Gateway

```bash
# Obtener IP pública
APPGW_IP=$(terraform output -raw application_gateway_public_ip)

# Probar endpoints
curl http://$APPGW_IP/api/health
curl http://$APPGW_IP/pdf/health
curl http://$APPGW_IP/data/health
```

## 🔍 Monitoreo y Logs

### Ver logs de pods:
```bash
kubectl logs -f deployment/pdf-generator -n multicloud-dr
kubectl logs -f deployment/api-gateway -n multicloud-dr
kubectl logs -f deployment/data-processor -n multicloud-dr
```

### Acceder a Azure Monitor:
```bash
# Abrir portal de Azure
az portal

# O directamente:
WORKSPACE_ID=$(terraform output -raw log_analytics_workspace_id)
echo "Log Analytics: https://portal.azure.com/#resource$WORKSPACE_ID"
```

### Verificar métricas de AKS:
```bash
kubectl top nodes
kubectl top pods -n multicloud-dr
```

## 🔄 Replicación de Datos

### CosmosDB ↔ DynamoDB

La sincronización se debe implementar a nivel de aplicación o mediante:
- AWS DMS (Database Migration Service)
- Azure Cosmos DB Change Feed + Azure Functions
- Custom Lambda/Function sync service

### S3 → Blob Storage

```bash
# Verificar pipeline de Data Factory
az datafactory pipeline show \
  --resource-group rg-multicloud-dr-prod \
  --factory-name $(terraform output -raw data_factory_name) \
  --name S3ToBlobReplicationPipeline

# Ejecutar manualmente
az datafactory pipeline create-run \
  --resource-group rg-multicloud-dr-prod \
  --factory-name $(terraform output -raw data_factory_name) \
  --name S3ToBlobReplicationPipeline
```

## 🧪 Testing Multicloud

### Test de conectividad AWS → Azure:
```bash
# Desde un pod en AWS ECS/EKS
curl http://10.20.1.x:8080/health

# Desde un pod en Azure AKS
kubectl exec -it deployment/api-gateway -n multicloud-dr -- \
  curl http://10.0.x.x:8080/health  # AWS private IP
```

### Test de failover:
```bash
# Simular falla en AWS
# El tráfico debe ser manejado por Azure

# Verificar estado de servicios
kubectl get pods -n multicloud-dr -w
```

## 📊 Costos Estimados

**Infraestructura Azure (mensual):**
- AKS (2 nodos D2s_v3): ~$140
- CosmosDB (Serverless): ~$50-200 (según uso)
- Blob Storage (GRS): ~$20-50
- Application Gateway v2: ~$140
- VPN Gateway (VpnGw1): ~$140
- Data Factory: ~$10-30
- Log Analytics: ~$20

**Total aproximado: $520-720/mes**

## 🛠️ Troubleshooting

### Problema: Pods no inician
```bash
# Ver eventos
kubectl describe pod <pod-name> -n multicloud-dr

# Verificar logs
kubectl logs <pod-name> -n multicloud-dr --previous

# Verificar secrets
kubectl get secret azure-config -n multicloud-dr -o yaml
```

### Problema: No hay conectividad AWS-Azure
```bash
# Verificar VPN Gateway
az network vnet-gateway show \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-vpn-gateway

# Ver logs de VPN
az monitor diagnostic-settings show \
  --resource $(terraform output -raw vnet_id)
```

### Problema: Application Gateway no responde
```bash
# Verificar backend health
az network application-gateway show-backend-health \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-appgw
```

## 🗑️ Destruir Infraestructura

```bash
# CUIDADO: Esto eliminará TODOS los recursos

# Primero eliminar recursos de Kubernetes
kubectl delete namespace multicloud-dr

# Luego destruir infraestructura Terraform
terraform destroy -auto-approve
```

## 📚 Documentación Adicional

- [Azure AKS Documentation](https://docs.microsoft.com/azure/aks/)
- [CosmosDB API for MongoDB](https://docs.microsoft.com/azure/cosmos-db/mongodb-introduction)
- [Azure VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## 👥 Soporte

Para problemas o preguntas:
1. Revisar logs en Azure Portal
2. Verificar Application Insights
3. Revisar documentación de Terraform
4. Contactar al equipo de DevOps

---

**Última actualización**: Noviembre 2025  
**Versión**: 1.0.0  
**Autor**: Equipo Multicloud DR

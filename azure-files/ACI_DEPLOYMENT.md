# Azure Container Instances Deployment (sin Kubernetes)

## 🎯 Cambios Implementados

### Arquitectura
Se ha configurado **Azure Container Instances (ACI)** para replicar la funcionalidad de **AWS ECS**, evitando el uso de Kubernetes (AKS).

### Servicios Desplegados

Los siguientes contenedores se desplegarán desde el ACR `multiclouddrnicolas.azurecr.io`:

1. **API Gateway** (Puerto 8080)
   - Imagen: `multiclouddrnicolas.azurecr.io/multicloud-dr/api-gateway:latest`
   - Endpoint: `/api/*`

2. **PDF Generator** (Puerto 8081)
   - Imagen: `multiclouddrnicolas.azurecr.io/multicloud-dr/pdf-generator:latest`
   - Endpoint: `/pdf/*`

3. **Data Processor** (Puerto 8082)
   - Imagen: `multiclouddrnicolas.azurecr.io/multicloud-dr/data-processor:latest`
   - Endpoint: `/data/*`

### Componentes Configurados

#### 1. **Azure Container Instances** (`aci.tf`)
- Container Groups para cada microservicio
- Health checks y readiness probes
- Integración con CosmosDB y Storage Account
- Logs centralizados en Log Analytics
- Red privada (subnet delegada)

#### 2. **Application Gateway** (`appgateway.tf`)
- Configurado para enrutar tráfico a los ACIs
- Backend pools apuntando a IPs privadas de los contenedores
- Health probes para cada servicio
- Enrutamiento basado en paths

#### 3. **Networking** (`network.tf`)
- Subnet dedicada para ACI con delegación
- NSG con reglas de seguridad
- Conectividad VPN con AWS

## 🚀 Despliegue

### Prerequisitos

1. **Credenciales ACR**: Necesitas usuario y contraseña del ACR `multiclouddrnicolas`

```bash
# Obtener credenciales del ACR
az acr credential show --name multiclouddrnicolas --resource-group <resource-group>
```

2. **Actualizar variables**: Edita `terraform.tfvars` o usa variables de entorno:

```hcl
# terraform.tfvars
acr_name           = "multiclouddrnicolas"
acr_admin_username = "<username-from-acr>"
acr_admin_password = "<password-from-acr>"

# Configuración de recursos ACI
aci_cpu    = 1      # CPU cores
aci_memory = 1.5    # GB de memoria
```

### Pasos de Despliegue

```bash
# 1. Inicializar Terraform
cd azure-files
terraform init

# 2. Validar configuración
terraform validate

# 3. Ver plan de despliegue
terraform plan

# 4. Aplicar cambios
terraform apply

# 5. Obtener outputs importantes
terraform output application_gateway_public_ip
terraform output gateway_endpoint
terraform output aci_api_gateway_ip
terraform output aci_pdf_generator_ip
terraform output aci_data_processor_ip
```

## 📊 Verificación del Despliegue

### 1. Verificar Container Instances

```bash
# Listar container groups
az container list --resource-group rg-multicloud-dr-prod --output table

# Ver logs de un contenedor
az container logs --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway

# Ver estado
az container show --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway
```

### 2. Probar Endpoints

```bash
# Obtener IP del Application Gateway
GATEWAY_IP=$(terraform output -raw application_gateway_public_ip)

# Health check
curl http://$GATEWAY_IP/health

# API Gateway
curl http://$GATEWAY_IP/api/info

# PDF Generator
curl -X POST http://$GATEWAY_IP/pdf/generate \
  -H "Content-Type: application/json" \
  -d '{"content": "Test PDF"}'

# Data Processor
curl -X POST http://$GATEWAY_IP/data/save \
  -H "Content-Type: application/json" \
  -d '{"data": "test"}'
```

### 3. Monitoreo

```bash
# Ver logs en Log Analytics
az monitor log-analytics query \
  --workspace <workspace-id> \
  --analytics-query "ContainerInstanceLog_CL | where TimeGenerated > ago(1h)"
```

## 🔧 Configuración de Variables de Entorno

Los contenedores están configurados con las siguientes variables:

### API Gateway
- `AZURE_REGION`: Región de Azure
- `COSMOSDB_ENDPOINT`: Endpoint de CosmosDB
- `COSMOSDB_DATABASE`: Nombre de la base de datos
- `COSMOSDB_KEY`: Clave de acceso (secure)

### PDF Generator
- `AZURE_REGION`: Región de Azure
- `STORAGE_ACCOUNT_NAME`: Nombre de la cuenta de almacenamiento
- `COSMOSDB_ENDPOINT`: Endpoint de CosmosDB
- `COSMOSDB_DATABASE`: Nombre de la base de datos
- `STORAGE_CONTAINER_NAME`: Contenedor de PDFs
- `COSMOSDB_KEY`: Clave de acceso (secure)
- `STORAGE_CONNECTION_STRING`: String de conexión (secure)

### Data Processor
- `AZURE_REGION`: Región de Azure
- `COSMOSDB_ENDPOINT`: Endpoint de CosmosDB
- `COSMOSDB_DATABASE`: Nombre de la base de datos
- `COSMOSDB_KEY`: Clave de acceso (secure)

## 🔄 Comparación ECS vs ACI

| Característica | AWS ECS | Azure ACI |
|----------------|---------|-----------|
| Orquestación | Cluster ECS | Container Groups |
| Networking | VPC + ALB | VNet + App Gateway |
| Escalado | Auto Scaling Groups | Manual (futuro: KEDA) |
| Logs | CloudWatch | Log Analytics |
| Health Checks | Target Group | Liveness/Readiness Probes |
| Precio | Por hora de tarea | Por segundo de ejecución |

## 📝 Archivos Modificados

### AWS (terrafiles/)
- ✅ `outputs.tf`: Agregados outputs del gateway ALB

### Azure (azure-files/)
- ✅ `aci.tf`: Nuevo archivo con Container Instances
- ✅ `variables.tf`: Variables para ACI y ACR
- ✅ `network.tf`: Subnet ACI con delegación y NSG
- ✅ `appgateway.tf`: Backend pools apuntando a ACIs
- ✅ `outputs.tf`: Outputs de IPs de ACI y gateway

## 🎯 Outputs Importantes

### AWS
```bash
terraform output alb_dns_name
terraform output gateway_endpoint
terraform output gateway_health_endpoint
```

### Azure
```bash
terraform output application_gateway_public_ip
terraform output gateway_endpoint
terraform output aci_api_gateway_ip
terraform output aci_pdf_generator_ip
terraform output aci_data_processor_ip
```

## 🚨 Troubleshooting

### Container no inicia
```bash
# Ver eventos del container
az container show --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway

# Ver logs detallados
az container logs --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway --follow
```

### Problemas de networking
```bash
# Verificar NSG
az network nsg rule list --resource-group rg-multicloud-dr-prod --nsg-name multicloud-dr-aci-nsg

# Verificar subnet delegation
az network vnet subnet show --resource-group rg-multicloud-dr-prod --vnet-name multicloud-dr-vnet --name multicloud-dr-aci-subnet
```

### Application Gateway no puede alcanzar ACI
```bash
# Verificar backend health
az network application-gateway show-backend-health \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-appgw
```

## 📚 Recursos Adicionales

- [Azure Container Instances Documentation](https://docs.microsoft.com/azure/container-instances/)
- [Application Gateway Path-based Routing](https://docs.microsoft.com/azure/application-gateway/url-route-overview)
- [ACI Virtual Network Integration](https://docs.microsoft.com/azure/container-instances/container-instances-vnet)

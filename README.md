# 🌐 Multicloud Disaster Recovery - Terraform Infrastructure

Infraestructura como código para despliegue de microservicios en AWS (ECS) y Azure (ACI) con replicación de datos.

## 📁 Estructura del Proyecto

```
terraform-files/
├── terrafiles/          # AWS Infrastructure (ECS + ALB)
├── azure-files/         # Azure Infrastructure (ACI + App Gateway)
└── CHANGES_SUMMARY.md   # Resumen detallado de cambios
```

## 🚀 Despliegue Rápido

### AWS - ECS + Application Load Balancer

```bash
cd terrafiles
terraform init
terraform plan
terraform apply

# Verificar gateway
./verify-aws-gateway.sh
```

**Outputs importantes:**
- `alb_dns_name`: DNS del Application Load Balancer
- `gateway_endpoint`: Endpoint principal del gateway
- `gateway_health_endpoint`: Health check endpoint

### Azure - Container Instances + Application Gateway

```bash
cd azure-files

# 1. Configurar credenciales ACR
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con credenciales de multiclouddrnicolas.azurecr.io

# 2. Desplegar con script automático
./deploy-azure-aci.sh

# O manual:
terraform init
terraform plan
terraform apply
```

**Outputs importantes:**
- `application_gateway_public_ip`: IP pública del App Gateway
- `gateway_endpoint`: Endpoint principal del gateway
- `aci_*_ip`: IPs privadas de los Container Instances

## 🏗️ Arquitectura

### AWS (ECS)
```
Internet → ALB → ECS Fargate Tasks
                 ├─ API Gateway (8080)
                 ├─ PDF Generator (8081)
                 └─ Data Processor (8082)
                     ↓
                 DynamoDB + S3
```

### Azure (ACI)
```
Internet → App Gateway → Container Instances
                          ├─ API Gateway (8080)
                          ├─ PDF Generator (8081)
                          └─ Data Processor (8082)
                              ↓
                          CosmosDB + Storage
```

## 🐳 Imágenes de Contenedores

### AWS ECR
```
503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/api-gateway:latest
503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/pdf-generator:latest
503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/data-processor:latest
```

### Azure ACR
```
multiclouddrnicolas.azurecr.io/multicloud-dr/api-gateway:latest
multiclouddrnicolas.azurecr.io/multicloud-dr/pdf-generator:latest
multiclouddrnicolas.azurecr.io/multicloud-dr/data-processor:latest
```

## 📚 Documentación Detallada

- **[CHANGES_SUMMARY.md](./CHANGES_SUMMARY.md)** - Resumen completo de cambios realizados
- **[azure-files/ACI_DEPLOYMENT.md](./azure-files/ACI_DEPLOYMENT.md)** - Guía completa de despliegue ACI
- **[azure-files/terraform.tfvars.example](./azure-files/terraform.tfvars.example)** - Ejemplo de variables

## 🔧 Configuración Requerida

### AWS
- Credenciales AWS configuradas (`aws configure`)
- Región: `us-east-1`
- Imágenes ya subidas a ECR

### Azure
- Azure CLI instalado y autenticado (`az login`)
- Región: `eastus`
- Credenciales del ACR `multiclouddrnicolas`

### Obtener Credenciales ACR
```bash
az acr credential show --name multiclouddrnicolas
```

## 🎯 Endpoints de los Servicios

### AWS
```bash
# Obtener DNS del ALB
terraform output -raw alb_dns_name

# Endpoints
http://<ALB_DNS>/health          # Health check
http://<ALB_DNS>/api/*           # API Gateway
http://<ALB_DNS>/pdf/*           # PDF Generator
http://<ALB_DNS>/data/*          # Data Processor
```

### Azure
```bash
# Obtener IP del App Gateway
terraform output -raw application_gateway_public_ip

# Endpoints
http://<APP_GW_IP>/health        # Health check
http://<APP_GW_IP>/api/*         # API Gateway
http://<APP_GW_IP>/pdf/*         # PDF Generator
http://<APP_GW_IP>/data/*        # Data Processor
```

## 🔍 Verificación

### AWS
```bash
cd terrafiles
./verify-aws-gateway.sh

# O manualmente
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://$ALB_DNS/health
```

### Azure
```bash
cd azure-files
GATEWAY_IP=$(terraform output -raw application_gateway_public_ip)
curl http://$GATEWAY_IP/health
```

## 🆚 Comparación de Servicios

| Componente | AWS | Azure |
|------------|-----|-------|
| **Compute** | ECS Fargate | Container Instances (ACI) |
| **Load Balancer** | Application Load Balancer | Application Gateway |
| **Database** | DynamoDB | CosmosDB (MongoDB API) |
| **Storage** | S3 | Blob Storage |
| **Logs** | CloudWatch | Log Analytics |
| **Networking** | VPC | Virtual Network |

## 📊 Características

- ✅ **Sin Kubernetes**: Uso de servicios nativos (ECS/ACI)
- ✅ **Auto-scaling**: Configurado en AWS, manual en Azure
- ✅ **Health Checks**: Probes configurados en ambos clouds
- ✅ **Logs Centralizados**: CloudWatch y Log Analytics
- ✅ **Networking Privado**: Subnets privadas para contenedores
- ✅ **Path-based Routing**: Enrutamiento por paths en ambos LBs
- ✅ **VPN Inter-cloud**: Conectividad AWS ↔ Azure (opcional)

## 🚨 Troubleshooting

### AWS
```bash
# Ver logs de CloudWatch
aws logs tail /ecs/multicloud-dr/api-gateway --follow

# Estado de servicios ECS
aws ecs describe-services --cluster multicloud-dr-cluster --services <service-name>

# Health del ALB
aws elbv2 describe-target-health --target-group-arn <tg-arn>
```

### Azure
```bash
# Ver logs de contenedores
az container logs --resource-group rg-multicloud-dr-prod --name multicloud-dr-api-gateway --follow

# Estado de Container Instances
az container list --resource-group rg-multicloud-dr-prod --output table

# Health del App Gateway
az network application-gateway show-backend-health --resource-group rg-multicloud-dr-prod --name multicloud-dr-appgw
```

## 🧹 Limpieza

```bash
# AWS
cd terrafiles
terraform destroy

# Azure
cd azure-files
terraform destroy
```

## 📝 Notas Importantes

1. **ACR Existente**: Se usa el ACR `multiclouddrnicolas` ya existente
2. **Imágenes Pre-subidas**: Las imágenes ya están en los registros
3. **No Kubernetes**: Se usa ACI en lugar de AKS para simplicidad
4. **Equivalencia**: ACI es el equivalente de ECS Fargate en Azure

## 👥 Contribución

Para cambios o mejoras, consulta `CHANGES_SUMMARY.md` para entender la arquitectura actual.

## 📄 Licencia

Este proyecto es parte del curso de Electiva Cloud - Ingeniería de Sistemas 2025-II

# 🚀 Quick Start Guide - Azure Multicloud Deployment

## ⚡ Despliegue Rápido (15 minutos)

### 1. Prerequisitos
```bash
# Instalar herramientas necesarias (si no están instaladas)
sudo apt-get update
sudo apt-get install -y curl unzip

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/
```

### 2. Login Azure
```bash
cd azure-files
az login
az account set --subscription "cf358c01-372e-49c2-bc60-72ab0fb8d928"
```

### 3. Desplegar Infraestructura
```bash
# Opción automática (recomendado)
./deploy.sh

# O manual:
terraform init
terraform plan
terraform apply -auto-approve
```

### 4. Configurar kubectl
```bash
az aks get-credentials \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-aks
```

### 5. Preparar Imágenes Docker
```bash
# Build y push automático
./build-push-images.sh

# O manual (ver README.md para comandos completos)
```

### 6. Configurar Secrets
```bash
./configure-secrets.sh
```

### 7. Desplegar Microservicios
```bash
kubectl apply -f k8s-manifests/
kubectl get pods -n multicloud-dr -w
```

### 8. Probar la Aplicación
```bash
APPGW_IP=$(terraform output -raw application_gateway_public_ip)
curl http://$APPGW_IP/api/health
```

## 📋 Checklist Completo

- [ ] Azure CLI instalado y autenticado
- [ ] Terraform instalado (>= 1.0)
- [ ] kubectl instalado
- [ ] Infraestructura Azure desplegada
- [ ] VPN Gateway IP obtenida
- [ ] AWS VPN configurado (ver VPN_CONFIGURATION.md)
- [ ] AKS cluster accesible
- [ ] Imágenes Docker en ACR
- [ ] Secrets de Kubernetes configurados
- [ ] Microservicios desplegados en AKS
- [ ] Application Gateway funcionando
- [ ] Conectividad AWS ↔ Azure verificada
- [ ] Monitoreo configurado

## 🔧 Comandos Útiles

### Verificar estado de recursos:
```bash
# Terraform
terraform show
terraform output

# AKS
kubectl get nodes
kubectl get pods -n multicloud-dr
kubectl get services -n multicloud-dr
kubectl top nodes

# Azure CLI
az resource list --resource-group rg-multicloud-dr-prod --output table
```

### Ver logs:
```bash
# Pods
kubectl logs -f deployment/api-gateway -n multicloud-dr

# Azure Monitor
az monitor log-analytics query \
  --workspace $(terraform output -raw log_analytics_workspace_id) \
  --analytics-query "ContainerLog | limit 100"
```

### Escalar servicios:
```bash
kubectl scale deployment api-gateway --replicas=4 -n multicloud-dr
```

### Actualizar imagen:
```bash
kubectl set image deployment/api-gateway \
  api-gateway=$ACR_SERVER/api-gateway:v2 \
  -n multicloud-dr
```

## 🆘 Solución Rápida de Problemas

### Pods no inician:
```bash
kubectl describe pod <pod-name> -n multicloud-dr
kubectl logs <pod-name> -n multicloud-dr
```

### No hay conectividad:
```bash
# Verificar VPN
az network vpn-connection show \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-azure-to-aws-vpn

# Test desde pod
kubectl exec -it deployment/api-gateway -n multicloud-dr -- ping 10.0.1.1
```

### Application Gateway no responde:
```bash
az network application-gateway show-backend-health \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-appgw
```

## 📊 Información Importante

### Recursos Creados:
- 1 Resource Group
- 1 VNet con 4 subnets
- 1 AKS cluster (2 node pools)
- 1 Azure Container Registry
- 1 CosmosDB account (2 regiones)
- 1 Storage Account + Blob Containers
- 1 Data Factory
- 1 Application Gateway
- 1 VPN Gateway
- Log Analytics + Application Insights

### Costos Estimados:
- **Mensual**: $520-720 USD
- **Por hora**: ~$0.70-1.00 USD

### Regiones:
- **Principal**: East US
- **Secundaria**: West US 2 (replicación)

## 📞 Soporte

Para ayuda adicional:
- README.md - Guía completa
- VPN_CONFIGURATION.md - Configuración VPN
- Azure Portal - https://portal.azure.com
- Terraform Docs - https://registry.terraform.io/providers/hashicorp/azurerm

---

**¡Feliz deployment! 🎉**

# 🔧 SOLUCIÓN RÁPIDA - Recursos Faltantes

## 📋 Situación Actual

Después de ejecutar `terraform refresh`, tenemos:

### ✅ Recursos que EXISTEN:
- Resource Group: `rg-multicloud-dr-prod-v2`
- VNet: `10.20.0.0/16`
- VPN Gateway (funcionando)
- ACR con las 3 imágenes Docker

### ❌ Recursos que NO EXISTEN (outputs null):
- Subnet ACI (`10.20.4.0/24`)
- CosmosDB
- Application Gateway
- 3 Container Instances (pdf-generator, api-gateway, data-processor)

## 🚀 Solución

### Opción 1: Rápida (Recomendada)

```bash
cd azure-files
terraform apply
```

Esto creará **todos** los recursos faltantes en un solo comando.

### Opción 2: Incremental (Más control)

```bash
cd azure-files
chmod +x apply-incremental.sh
./apply-incremental.sh
```

Crea recursos paso a paso:
1. Subnet ACI
2. CosmosDB (tarda 5-10 min)
3. Storage (verificación)
4. Application Gateway
5. Container Instances

### Opción 3: Script interactivo

```bash
cd azure-files
chmod +x EJECUTAR-ESTO.sh
./EJECUTAR-ESTO.sh
```

## 📊 Verificar después

```bash
# Ver outputs
terraform output

# Verificar Container Instances
az container list --resource-group rg-multicloud-dr-prod-v2 -o table

# Obtener IPs
az container show --resource-group rg-multicloud-dr-prod-v2 \
  --name multicloud-dr-v2-pdf-generator \
  --query "ipAddress.ip" -o tsv

# Probar Application Gateway
APPGW_IP=$(terraform output -raw application_gateway_public_ip)
curl http://$APPGW_IP/health
```

## 🎯 Por qué falló antes

Los errores anteriores fueron:
- **HTTP response nil**: Timeout de Azure API durante creación masiva
- **Context canceled**: Operaciones canceladas
- **VPN Gateway exists**: Ya existía de un apply anterior parcial

**Solución**: Terraform ahora creará solo lo que falta, sin tocar lo que ya existe.

## ⏱️ Tiempo estimado

- Subnet ACI: 30 segundos
- CosmosDB: **5-10 minutos** (el más lento)
- Application Gateway: 3-5 minutos
- Container Instances: 1-2 minutos

**Total: ~10-15 minutos**

## 🔍 Troubleshooting

Si falla algún recurso:

```bash
# Ver plan sin aplicar
terraform plan

# Aplicar recurso específico
terraform apply -target=azurerm_cosmosdb_account.main

# Ver logs de errores
TF_LOG=DEBUG terraform apply 2>&1 | tee terraform-debug.log
```

## ✅ Resultado esperado

Después del apply exitoso, `terraform output` debería mostrar:

```
aci_api_gateway_ip = "10.20.4.X"
aci_data_processor_ip = "10.20.4.X"
aci_pdf_generator_ip = "10.20.4.X"
cosmosdb_endpoint = "https://multicloud-dr-v2-cosmos-production.documents.azure.com:443/"
application_gateway_public_ip = "X.X.X.X"
```

**Sin valores `null`**.

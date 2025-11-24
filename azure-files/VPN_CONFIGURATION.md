# 🔐 Guía de Configuración VPN AWS ↔ Azure

## Objetivo
Establecer una conexión VPN Site-to-Site entre AWS y Azure usando IPSec para permitir comunicación privada entre ambas nubes.

## Arquitectura de Conectividad

```
┌─────────────────┐         VPN IPSec          ┌─────────────────┐
│   AWS VPC       │◄──────────────────────────►│   Azure VNet    │
│  10.0.0.0/16    │   Internet Gateway         │  10.20.0.0/16   │
│                 │                             │                 │
│  ECS Services   │    Encrypted Tunnel         │  AKS Services   │
│  DynamoDB       │                             │  CosmosDB       │
│  S3             │                             │  Blob Storage   │
└─────────────────┘                             └─────────────────┘
```

## Paso 1: Obtener Información de Azure

### Después de desplegar Azure con Terraform:

```bash
cd azure-files

# Obtener IP pública del VPN Gateway de Azure
AZURE_VPN_IP=$(terraform output -raw vpn_gateway_public_ip)
echo "Azure VPN Gateway IP: $AZURE_VPN_IP"

# Guardar para uso posterior
echo $AZURE_VPN_IP > azure_vpn_ip.txt
```

**Información necesaria de Azure:**
- ✅ VPN Gateway Public IP: `X.X.X.X`
- ✅ Azure VNet CIDR: `10.20.0.0/16`
- ✅ Shared Key: (mismo valor configurado en variables.tf)

## Paso 2: Configurar AWS VPN

### Opción A: Configuración Manual en AWS Console

#### 2.1 Crear Customer Gateway

1. Ir a VPC → Customer Gateways
2. Click "Create Customer Gateway"
3. Configurar:
   - **Name**: `multicloud-azure-cgw`
   - **BGP ASN**: `65000` (o cualquier ASN privado)
   - **IP Address**: `<AZURE_VPN_GATEWAY_IP>`
   - **Certificate ARN**: (dejar vacío)
4. Click "Create Customer Gateway"

#### 2.2 Crear Virtual Private Gateway (si no existe)

1. Ir a VPC → Virtual Private Gateways
2. Click "Create Virtual Private Gateway"
3. Configurar:
   - **Name**: `multicloud-vgw`
   - **ASN**: Amazon default ASN
4. Click "Create Virtual Private Gateway"
5. **Attach to VPC**: Seleccionar tu VPC de multicloud

#### 2.3 Crear VPN Connection

1. Ir a VPC → Site-to-Site VPN Connections
2. Click "Create VPN Connection"
3. Configurar:
   - **Name**: `aws-to-azure-vpn`
   - **Target Gateway Type**: Virtual Private Gateway
   - **Virtual Private Gateway**: `multicloud-vgw`
   - **Customer Gateway**: `multicloud-azure-cgw`
   - **Routing Options**: Static
   - **Static IP Prefixes**: `10.20.0.0/16`
   - **Tunnel Options**:
     - **Inside IP CIDR for Tunnel 1**: `169.254.21.0/30`
     - **Pre-Shared Key for Tunnel 1**: `<YOUR_SHARED_KEY>`
4. Click "Create VPN Connection"

#### 2.4 Actualizar Route Tables

1. Ir a VPC → Route Tables
2. Para cada route table de subnets privadas:
   - Click en la route table
   - Tab "Routes" → "Edit routes"
   - Add route:
     - **Destination**: `10.20.0.0/16`
     - **Target**: Virtual Private Gateway `multicloud-vgw`
   - Save changes

### Opción B: Configuración con Terraform (Recomendado)

Agregar al archivo AWS `terrafiles/vpn.tf`:

```hcl
# Customer Gateway (Azure VPN endpoint)
resource "aws_customer_gateway" "azure" {
  bgp_asn    = 65000
  ip_address = var.azure_vpn_gateway_ip  # IP obtenida de Azure
  type       = "ipsec.1"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-azure-cgw"
    }
  )
}

# Virtual Private Gateway
resource "aws_vpn_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-vgw"
    }
  )
}

# VPN Connection to Azure
resource "aws_vpn_connection" "azure" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.azure.id
  type                = "ipsec.1"
  static_routes_only  = true

  # Tunnel configuration
  tunnel1_preshared_key = var.vpn_shared_key
  tunnel1_inside_cidr   = "169.254.21.0/30"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-to-azure-vpn"
    }
  )
}

# Static route to Azure
resource "aws_vpn_connection_route" "azure" {
  destination_cidr_block = "10.20.0.0/16"  # Azure VNet CIDR
  vpn_connection_id      = aws_vpn_connection.azure.id
}

# Enable route propagation
resource "aws_vpn_gateway_route_propagation" "private" {
  count          = length(var.availability_zones)
  vpn_gateway_id = aws_vpn_gateway.main.id
  route_table_id = aws_route_table.private[count.index].id
}

# Output VPN details
output "vpn_connection_id" {
  description = "VPN Connection ID"
  value       = aws_vpn_connection.azure.id
}

output "vpn_gateway_public_ip" {
  description = "AWS VPN Gateway Public IP (use in Azure)"
  value       = aws_vpn_connection.azure.tunnel1_address
}
```

Agregar variable en `terrafiles/variables.tf`:

```hcl
variable "azure_vpn_gateway_ip" {
  description = "Azure VPN Gateway Public IP"
  type        = string
  default     = "X.X.X.X"  # IP obtenida de Azure
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
  default     = "MySecureSharedKey123!"  # Mismo que en Azure
}
```

Aplicar cambios:

```bash
cd terrafiles
terraform apply
```

## Paso 3: Actualizar Azure con IP de AWS

Una vez creada la VPN en AWS, obtener la IP pública:

```bash
# Si usaste Terraform en AWS
cd terrafiles
AWS_VPN_IP=$(terraform output -raw vpn_gateway_public_ip)
echo "AWS VPN IP: $AWS_VPN_IP"
```

O desde AWS Console:
1. VPC → Site-to-Site VPN Connections
2. Seleccionar tu conexión
3. Tab "Tunnel Details"
4. Copiar "Outside IP Address" del Tunnel 1

Actualizar Azure:

```bash
cd azure-files

# Editar variables.tf o crear terraform.tfvars
cat > terraform.tfvars <<EOF
aws_vpn_gateway_ip = "$AWS_VPN_IP"
EOF

# Aplicar cambios
terraform apply -auto-approve
```

## Paso 4: Verificar Conectividad

### Desde AWS (ECS Task):

```bash
# Conectarse a un contenedor ECS
aws ecs execute-command \
  --cluster multicloud-dr-cluster \
  --task <TASK_ID> \
  --container api-gateway \
  --interactive \
  --command "/bin/sh"

# Probar conectividad a Azure
ping 10.20.1.10  # IP de un servicio en Azure
curl http://10.20.1.10:8080/health
```

### Desde Azure (AKS Pod):

```bash
# Conectarse a un pod
kubectl exec -it deployment/api-gateway -n multicloud-dr -- /bin/sh

# Probar conectividad a AWS
ping 10.0.1.10  # IP de un servicio en AWS
curl http://10.0.1.10:8080/health
```

### Verificar estado del túnel en AWS:

```bash
# CLI
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <VPN_CONNECTION_ID> \
  --query 'VpnConnections[0].VgwTelemetry'

# Terraform
cd terrafiles
terraform output vpn_connection_id
```

### Verificar estado del túnel en Azure:

```bash
# Ver estado de conexión
az network vpn-connection show \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-azure-to-aws-vpn \
  --query 'connectionStatus'

# Ver métricas
az monitor metrics list \
  --resource $(az network vpn-connection show \
    --resource-group rg-multicloud-dr-prod \
    --name multicloud-dr-azure-to-aws-vpn \
    --query 'id' -o tsv) \
  --metric 'TunnelIngressBytes'
```

## Paso 5: Configurar Security Groups y NSGs

### En AWS (Security Groups):

Agregar a `terrafiles/security.tf`:

```hcl
# Allow traffic from Azure VNet
resource "aws_security_group_rule" "allow_azure" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["10.20.0.0/16"]
  security_group_id = aws_security_group.ecs_tasks.id
  description       = "Allow all traffic from Azure VNet"
}
```

### En Azure (NSGs):

Ya configurado en `network.tf`, verificar que exista:

```hcl
security_rule {
  name                       = "Allow-AWS-VPC"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "*"
  source_address_prefix      = "10.0.0.0/16"
  # ...
}
```

## Troubleshooting

### El túnel no se establece:

1. Verificar que ambos VPN Gateways estén en estado "Available"
2. Verificar que el Shared Key sea idéntico en ambos lados
3. Verificar que las IPs públicas sean correctas
4. Revisar logs de VPN Gateway en Azure Monitor
5. Revisar CloudWatch Logs en AWS

### Túnel UP pero no hay conectividad:

1. Verificar Route Tables en AWS
2. Verificar Route Tables en Azure (ya configuradas en Terraform)
3. Verificar Security Groups en AWS
4. Verificar NSGs en Azure
5. Verificar que los servicios estén escuchando en las IPs privadas

### Comandos de diagnóstico:

```bash
# AWS - Ver estado de túneles
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <VPN_CONNECTION_ID>

# Azure - Ver logs de VPN
az network vnet-gateway list-bgp-peer-status \
  --resource-group rg-multicloud-dr-prod \
  --name multicloud-dr-vpn-gateway

# Azure - Ver diagnósticos
az monitor diagnostic-settings show \
  --resource <VPN_GATEWAY_RESOURCE_ID>
```

## Monitoreo

### Métricas clave a monitorear:

**AWS CloudWatch:**
- `TunnelState`: Estado del túnel (0=Down, 1=Up)
- `TunnelDataIn`: Bytes entrantes
- `TunnelDataOut`: Bytes salientes

**Azure Monitor:**
- `TunnelIngressBytes`: Bytes entrantes
- `TunnelEgressBytes`: Bytes salientes
- `TunnelIngressPacketDropCount`: Paquetes descartados

### Alertas recomendadas:

```bash
# Azure - Crear alerta si el túnel cae
az monitor metrics alert create \
  --name "vpn-tunnel-down" \
  --resource-group rg-multicloud-dr-prod \
  --scopes <VPN_CONNECTION_ID> \
  --condition "avg TunnelEgressBytes < 1" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Costos

**AWS:**
- VPN Connection: ~$36/mes
- Data Transfer OUT: $0.09/GB (primeros 10TB)

**Azure:**
- VPN Gateway (VpnGw1): ~$140/mes
- Data Transfer OUT: $0.087/GB (primeros 10TB)

**Total VPN: ~$176/mes + data transfer**

## Referencias

- [AWS VPN Documentation](https://docs.aws.amazon.com/vpn/)
- [Azure VPN Gateway](https://docs.microsoft.com/azure/vpn-gateway/)
- [IPSec Configuration](https://docs.microsoft.com/azure/vpn-gateway/vpn-gateway-about-vpn-devices)

---

**Última actualización**: Noviembre 2025

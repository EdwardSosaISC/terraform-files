# 📚 Azure Multicloud Infrastructure - Índice de Documentación

## 🎯 Inicio Rápido

**¿Primer despliegue?** → Empieza aquí:

1. 📖 **[QUICKSTART.md](./QUICKSTART.md)** - Guía rápida de 15 minutos
2. 🚀 **[deploy.sh](./deploy.sh)** - Script automatizado de despliegue
3. ✅ **[SUMMARY.md](./SUMMARY.md)** - Resumen completo del proyecto

---

## 📋 Documentación Disponible

### 📘 Guías Principales

| Documento | Descripción | Tiempo de Lectura |
|-----------|-------------|-------------------|
| **[README.md](./README.md)** | Guía completa y detallada con todos los pasos | 30-40 min |
| **[QUICKSTART.md](./QUICKSTART.md)** | Inicio rápido - Comandos esenciales | 5-10 min |
| **[SUMMARY.md](./SUMMARY.md)** | Resumen ejecutivo - ¿Qué hay aquí? | 10-15 min |
| **[VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md)** | Configuración VPN AWS ↔ Azure | 15-20 min |
| **[ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)** | Diagramas de arquitectura visual | 10 min |

### 🔧 Scripts de Automatización

| Script | Propósito | Uso |
|--------|-----------|-----|
| **[deploy.sh](./deploy.sh)** | Despliegue completo de infraestructura | `./deploy.sh` |
| **[configure-secrets.sh](./configure-secrets.sh)** | Configurar secrets de Kubernetes | `./configure-secrets.sh` |
| **[build-push-images.sh](./build-push-images.sh)** | Build y push de imágenes Docker | `./build-push-images.sh` |

---

## 🏗️ Archivos de Infraestructura

### Terraform Core Files

| Archivo | Recursos Creados |
|---------|------------------|
| **[providers.tf](./providers.tf)** | Provider Azure + autenticación |
| **[variables.tf](./variables.tf)** | Variables configurables del proyecto |
| **[main.tf](./main.tf)** | Resource Group + configuración base |
| **[outputs.tf](./outputs.tf)** | Outputs de todos los recursos |

### Componentes de Infraestructura

| Archivo | Servicios | Detalles |
|---------|-----------|----------|
| **[network.tf](./network.tf)** | Networking | VNet, Subnets, NSGs, VPN Gateway, Route Tables |
| **[aks.tf](./aks.tf)** | Kubernetes | AKS Cluster, Node Pools, ACR, RBAC |
| **[cosmosdb.tf](./cosmosdb.tf)** | Database | CosmosDB Account, Collections, Private Endpoint |
| **[storage.tf](./storage.tf)** | Storage | Blob Storage, Containers, Private Endpoint |
| **[datafactory.tf](./datafactory.tf)** | ETL/Replication | Data Factory, Pipelines, S3→Blob sync |
| **[appgateway.tf](./appgateway.tf)** | Load Balancer | Application Gateway, Routing Rules, Probes |
| **[monitoring.tf](./monitoring.tf)** | Observability | Log Analytics, App Insights, Alerts |

### Manifiestos Kubernetes

| Archivo | Descripción |
|---------|-------------|
| **[k8s-manifests/00-namespace.yaml](./k8s-manifests/00-namespace.yaml)** | Namespace multicloud-dr |
| **[k8s-manifests/01-configmap-secret.yaml](./k8s-manifests/01-configmap-secret.yaml)** | ConfigMaps y Secrets |
| **[k8s-manifests/02-pdf-generator.yaml](./k8s-manifests/02-pdf-generator.yaml)** | PDF Generator deployment + HPA |
| **[k8s-manifests/03-api-gateway.yaml](./k8s-manifests/03-api-gateway.yaml)** | API Gateway deployment + HPA |
| **[k8s-manifests/04-data-processor.yaml](./k8s-manifests/04-data-processor.yaml)** | Data Processor deployment + HPA |

---

## 🎓 Guías por Tarea

### Para Desplegar por Primera Vez

```bash
# 1. Leer primero
cat QUICKSTART.md

# 2. Ejecutar despliegue
./deploy.sh

# 3. Seguir instrucciones en pantalla
```

**Documentos relevantes:**
- [QUICKSTART.md](./QUICKSTART.md)
- [README.md](./README.md) (sección "Despliegue Paso a Paso")

### Para Configurar VPN con AWS

```bash
# 1. Leer guía VPN
cat VPN_CONFIGURATION.md

# 2. Obtener IP de Azure
terraform output vpn_gateway_public_ip

# 3. Configurar en AWS
# (seguir pasos en VPN_CONFIGURATION.md)
```

**Documentos relevantes:**
- [VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md)
- [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md) (sección "VPN Connectivity")

### Para Desplegar Microservicios

```bash
# 1. Build y push imágenes
./build-push-images.sh

# 2. Configurar secrets
./configure-secrets.sh

# 3. Desplegar a AKS
kubectl apply -f k8s-manifests/
```

**Documentos relevantes:**
- [README.md](./README.md) (sección "Fase 5 y 6")
- Manifiestos en [k8s-manifests/](./k8s-manifests/)

### Para Troubleshooting

```bash
# 1. Ver sección de troubleshooting
cat README.md | grep -A 50 "Troubleshooting"

# 2. Verificar logs
kubectl logs -f deployment/api-gateway -n multicloud-dr
```

**Documentos relevantes:**
- [README.md](./README.md) (sección "Troubleshooting")
- [QUICKSTART.md](./QUICKSTART.md) (sección "Solución Rápida")

### Para Entender la Arquitectura

```bash
# Visualizar diagramas
cat ARCHITECTURE_DIAGRAM.md
```

**Documentos relevantes:**
- [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)
- [SUMMARY.md](./SUMMARY.md) (sección "Mapeo de Servicios")
- [README.md](./README.md) (sección "Arquitectura")

---

## 🔍 Búsqueda Rápida

### Por Concepto

| Busco información sobre... | Ver documento... | Sección... |
|---------------------------|------------------|------------|
| **Costos** | [SUMMARY.md](./SUMMARY.md) | "Costos Estimados" |
| **IPs y Endpoints** | [SUMMARY.md](./SUMMARY.md) | "Información Clave" |
| **Variables configurables** | [variables.tf](./variables.tf) | Todo el archivo |
| **VPN Setup** | [VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md) | "Paso 1-5" |
| **Comandos kubectl** | [QUICKSTART.md](./QUICKSTART.md) | "Comandos Útiles" |
| **Autoscaling** | [README.md](./README.md) | Search "autoscaling" |
| **Monitoreo** | [monitoring.tf](./monitoring.tf) | Todo el archivo |
| **Security** | [network.tf](./network.tf) | NSGs section |
| **Database replication** | [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md) | "Data Replication Flow" |

### Por Servicio Azure

| Servicio Azure | Archivo Terraform | Documentación |
|----------------|-------------------|---------------|
| AKS | [aks.tf](./aks.tf) | [README.md](./README.md) - Fase 4 |
| CosmosDB | [cosmosdb.tf](./cosmosdb.tf) | [SUMMARY.md](./SUMMARY.md) - Databases |
| Blob Storage | [storage.tf](./storage.tf) | [README.md](./README.md) - Storage |
| Data Factory | [datafactory.tf](./datafactory.tf) | [README.md](./README.md) - Replicación |
| App Gateway | [appgateway.tf](./appgateway.tf) | [README.md](./README.md) - Load Balancing |
| VPN Gateway | [network.tf](./network.tf) | [VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md) |
| ACR | [aks.tf](./aks.tf) | [README.md](./README.md) - Fase 5 |
| Monitor | [monitoring.tf](./monitoring.tf) | [README.md](./README.md) - Monitoreo |

---

## 📊 Flujo de Lectura Recomendado

### Para Principiantes
```
1. SUMMARY.md (10 min) - Entender qué hay aquí
   ↓
2. ARCHITECTURE_DIAGRAM.md (10 min) - Ver el diseño
   ↓
3. QUICKSTART.md (5 min) - Comandos básicos
   ↓
4. Ejecutar ./deploy.sh
   ↓
5. Leer README.md según necesites
```

### Para Usuarios Avanzados
```
1. SUMMARY.md (5 min) - Revisión rápida
   ↓
2. Revisar variables.tf - Ajustar configuración
   ↓
3. Ejecutar terraform plan - Ver cambios
   ↓
4. VPN_CONFIGURATION.md - Si necesitas multicloud
   ↓
5. Desplegar y monitorear
```

### Para DevOps/SRE
```
1. ARCHITECTURE_DIAGRAM.md - Entender topología
   ↓
2. network.tf + security.tf - Revisar seguridad
   ↓
3. monitoring.tf - Configurar alertas
   ↓
4. README.md (Troubleshooting) - Procedimientos
   ↓
5. Implementar runbooks personalizados
```

---

## 🎯 Casos de Uso Comunes

### Caso 1: "Necesito desplegar todo desde cero"
👉 **Ruta:**
1. [QUICKSTART.md](./QUICKSTART.md)
2. `./deploy.sh`
3. [VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md) (si multicloud)

### Caso 2: "Solo quiero entender qué hace esto"
👉 **Ruta:**
1. [SUMMARY.md](./SUMMARY.md)
2. [ARCHITECTURE_DIAGRAM.md](./ARCHITECTURE_DIAGRAM.md)

### Caso 3: "Algo no funciona"
👉 **Ruta:**
1. [README.md](./README.md) - Sección Troubleshooting
2. [QUICKSTART.md](./QUICKSTART.md) - Solución Rápida
3. Verificar logs: `kubectl logs ...`

### Caso 4: "Quiero cambiar configuración"
👉 **Ruta:**
1. [variables.tf](./variables.tf) - Modificar valores
2. `terraform plan` - Ver cambios
3. `terraform apply` - Aplicar

### Caso 5: "Necesito costos detallados"
👉 **Ruta:**
1. [SUMMARY.md](./SUMMARY.md) - Sección Costos
2. Azure Portal - Cost Management

### Caso 6: "Quiero agregar un nuevo microservicio"
👉 **Ruta:**
1. Copiar `k8s-manifests/02-pdf-generator.yaml`
2. Modificar para nuevo servicio
3. Actualizar `appgateway.tf` - Agregar path rule
4. `terraform apply`
5. `kubectl apply -f k8s-manifests/`

---

## 📞 Soporte por Tema

| Necesito ayuda con... | Contacto/Recurso |
|----------------------|------------------|
| **Terraform** | [Terraform Docs](https://registry.terraform.io/providers/hashicorp/azurerm) |
| **Azure** | [Azure Docs](https://docs.microsoft.com/azure) |
| **Kubernetes** | [Kubernetes Docs](https://kubernetes.io/docs) |
| **VPN IPSec** | [VPN_CONFIGURATION.md](./VPN_CONFIGURATION.md) |
| **Este proyecto** | Ver documentos en este directorio |

---

## ✅ Checklist de Documentos Leídos

Usa esto para trackear tu progreso:

- [ ] 📄 INDEX.md (este archivo)
- [ ] 📖 SUMMARY.md
- [ ] 🚀 QUICKSTART.md
- [ ] 📚 README.md
- [ ] 🔐 VPN_CONFIGURATION.md
- [ ] 🏗️ ARCHITECTURE_DIAGRAM.md
- [ ] ⚙️ variables.tf
- [ ] 📜 outputs.tf

---

## 🔄 Actualización de Documentos

**Última actualización**: Noviembre 2025  
**Versión**: 1.0.0  
**Estado**: ✅ Production Ready

**Mantenimiento:**
- Revisar después de cada actualización de Azure Provider
- Actualizar costos trimestralmente
- Verificar versiones de Kubernetes soportadas

---

## 📩 Feedback

¿Encontraste un error en la documentación?  
¿Falta algo importante?  
¿Tienes sugerencias?

→ Abre un issue o contacta al equipo de DevOps

---

**¡Feliz deployment! 🎉**

*Recuerda: La mejor documentación es la que realmente usas.*

#!/bin/bash
# SOLUCIÓN FINAL - Ejecutar este script

echo "═══════════════════════════════════════════════════════════"
echo "🔧 SOLUCIÓN: Crear recursos faltantes de Azure"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "✅ Diagnóstico:"
echo "   - Resource Group existe"
echo "   - VNet existe"
echo "   - VPN Gateway existe"
echo "   - ACR con imágenes: ✅"
echo ""
echo "❌ Recursos faltantes:"
echo "   - Subnet ACI"
echo "   - CosmosDB"
echo "   - Application Gateway"
echo "   - Container Instances (3)"
echo ""
echo "───────────────────────────────────────────────────────────"
echo ""

cd "$(dirname "$0")"

# Opción simple: aplicar todo
echo "🚀 Opción 1: Aplicar terraform completo"
echo "   Este comando creará TODOS los recursos faltantes"
echo ""
echo "   Comando: terraform apply"
echo ""

# Opción incremental
echo "🔄 Opción 2: Aplicar de forma incremental (recomendado)"
echo "   Crea recursos uno por uno para mejor control"
echo ""
echo "   Script: ./apply-incremental.sh"
echo ""

echo "───────────────────────────────────────────────────────────"
read -p "Elige opción (1/2) o 'q' para salir: " OPTION

case $OPTION in
  1)
    echo ""
    echo "Ejecutando: terraform apply"
    terraform apply
    ;;
  2)
    if [ -f "./apply-incremental.sh" ]; then
      chmod +x ./apply-incremental.sh
      ./apply-incremental.sh
    else
      echo "❌ Error: apply-incremental.sh no encontrado"
      exit 1
    fi
    ;;
  q|Q)
    echo "Saliendo..."
    exit 0
    ;;
  *)
    echo "Opción inválida"
    exit 1
    ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "✅ VERIFICACIÓN FINAL"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Refresh y mostrar outputs
terraform refresh
terraform output

echo ""
echo "───────────────────────────────────────────────────────────"
echo "📊 Comandos de verificación:"
echo ""
echo "Container Instances:"
echo "  az container list --resource-group rg-multicloud-dr-prod-v2 -o table"
echo ""
echo "Application Gateway:"
echo "  APPGW_IP=\$(terraform output -raw application_gateway_public_ip)"
echo "  curl http://\$APPGW_IP/health"
echo ""
echo "Logs de Container:"
echo "  az container logs --resource-group rg-multicloud-dr-prod-v2 --name multicloud-dr-v2-pdf-generator"
echo ""

#!/bin/bash
# Script rápido para aplicar terraform completo

set -e

echo "🚀 Aplicando Terraform - Creación de recursos faltantes"
echo "======================================================="
echo ""

cd "$(dirname "$0")"

# Mostrar plan primero
echo "📋 Plan de ejecución:"
echo ""
terraform plan -out=tfplan

echo ""
read -p "¿Aplicar este plan? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Cancelado."
  rm -f tfplan
  exit 0
fi

# Aplicar
echo ""
echo "⚙️  Aplicando configuración..."
terraform apply tfplan

# Limpiar
rm -f tfplan

# Verificar
echo ""
echo "📊 Resultados:"
terraform output

echo ""
echo "✅ Completado"
echo ""
echo "Para verificar Container Instances:"
echo "  az container list --resource-group rg-multicloud-dr-prod-v2 -o table"

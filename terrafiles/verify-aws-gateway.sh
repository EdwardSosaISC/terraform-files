#!/bin/bash
# Script de verificación rápida para AWS ECS + ALB
# Uso: ./verify-aws-gateway.sh

set -e

echo "🔍 AWS ECS + ALB - Verificación del Gateway"
echo "==========================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Verificar que estamos en el directorio correcto
if [ ! -f "alb.tf" ]; then
    echo -e "${RED}❌ Error: No se encuentra alb.tf${NC}"
    echo "   Ejecuta este script desde el directorio terrafiles/"
    exit 1
fi

echo -e "${YELLOW}📋 Obteniendo información de Terraform...${NC}"
echo ""

# Obtener outputs
ALB_DNS=$(terraform output -raw alb_dns_name 2>/dev/null || echo "N/A")
GATEWAY_ENDPOINT=$(terraform output -raw gateway_endpoint 2>/dev/null || echo "N/A")
HEALTH_ENDPOINT=$(terraform output -raw gateway_health_endpoint 2>/dev/null || echo "N/A")

if [ "$ALB_DNS" = "N/A" ]; then
    echo -e "${RED}❌ No se pudo obtener información del ALB${NC}"
    echo "   Asegúrate de haber ejecutado 'terraform apply' primero"
    exit 1
fi

echo -e "${GREEN}✅ Información del ALB obtenida${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${BLUE}🌐 Application Load Balancer${NC}"
echo "   DNS Name: $ALB_DNS"
echo ""
echo -e "${BLUE}📍 Endpoints del Gateway${NC}"
echo "   Gateway:      $GATEWAY_ENDPOINT"
echo "   Health Check: $HEALTH_ENDPOINT"
echo ""
echo -e "${BLUE}🔗 Service Endpoints${NC}"
echo "   API Gateway:   http://$ALB_DNS/api/"
echo "   PDF Generator: http://$ALB_DNS/pdf/"
echo "   Data Proc:     http://$ALB_DNS/data/"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verificar endpoints
echo -e "${YELLOW}🔍 Verificando endpoints...${NC}"
echo ""

echo -n "   Health Check... "
if curl -s -f -m 10 "$HEALTH_ENDPOINT" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ Failed${NC}"
fi

echo -n "   API Gateway...  "
if curl -s -f -m 10 "http://$ALB_DNS/api/health" > /dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${YELLOW}⏳ Pending${NC}"
fi

echo ""

# Verificar servicios ECS
echo -e "${YELLOW}📦 Estado de los servicios ECS...${NC}"
echo ""

CLUSTER_NAME=$(terraform output -raw ecs_cluster_name 2>/dev/null || echo "multicloud-dr-cluster")

if command -v aws &> /dev/null; then
    echo "Servicios ECS:"
    aws ecs list-services --cluster "$CLUSTER_NAME" --query 'serviceArns[*]' --output text 2>/dev/null | \
        xargs -I {} aws ecs describe-services --cluster "$CLUSTER_NAME" --services {} \
        --query 'services[*].[serviceName,status,desiredCount,runningCount]' --output table 2>/dev/null || \
        echo -e "${YELLOW}⚠️  No se pudo obtener estado de servicios ECS${NC}"
else
    echo -e "${YELLOW}⚠️  AWS CLI no está instalado${NC}"
fi

echo ""
echo -e "${GREEN}✅ Verificación completada${NC}"
echo ""
echo "Para ver logs de CloudWatch:"
echo "  ${BLUE}aws logs tail /ecs/multicloud-dr/api-gateway --follow${NC}"
echo ""
echo "Para ver el estado del ALB:"
echo "  ${BLUE}terraform output${NC}"
echo ""

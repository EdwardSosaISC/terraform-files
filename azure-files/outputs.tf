# Resource Group
output "resource_group_name" {
  description = "Resource Group name"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Resource Group location"
  value       = azurerm_resource_group.main.location
}

# Networking
output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway Public IP (use this in AWS VPN configuration)"
  value       = azurerm_public_ip.vpn_gateway.ip_address
}

# AKS
output "aks_cluster_name" {
  description = "AKS Cluster name"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "AKS Cluster ID"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_kube_config" {
  description = "AKS kubectl config (sensitive)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_cluster_fqdn" {
  description = "AKS Cluster FQDN"
  value       = azurerm_kubernetes_cluster.main.fqdn
}

# ACR (Note: Using existing ACR multiclouddrnicolas)
output "acr_name" {
  description = "Azure Container Registry name being used"
  value       = var.acr_name
}

output "acr_login_server" {
  description = "ACR login server URL"
  value       = "${var.acr_name}.azurecr.io"
}

# Azure Container Instances
output "aci_pdf_generator_ip" {
  description = "PDF Generator Container Instance private IP"
  value       = azurerm_container_group.pdf_generator.ip_address
}

output "aci_api_gateway_ip" {
  description = "API Gateway Container Instance private IP"
  value       = azurerm_container_group.api_gateway.ip_address
}

output "aci_data_processor_ip" {
  description = "Data Processor Container Instance private IP"
  value       = azurerm_container_group.data_processor.ip_address
}

output "aci_log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID for ACI"
  value       = azurerm_log_analytics_workspace.aci.id
}

# CosmosDB
output "cosmosdb_endpoint" {
  description = "CosmosDB endpoint"
  value       = azurerm_cosmosdb_account.main.endpoint
}

output "cosmosdb_connection_strings" {
  description = "CosmosDB connection strings (deprecated - use primary_key)"
  value       = "Use cosmosdb_primary_key instead"
  sensitive   = false
}

output "cosmosdb_primary_key" {
  description = "CosmosDB primary key"
  value       = azurerm_cosmosdb_account.main.primary_key
  sensitive   = true
}

output "cosmosdb_database_name" {
  description = "CosmosDB database name"
  value       = azurerm_cosmosdb_mongo_database.main.name
}

# Storage
output "storage_account_name" {
  description = "Storage Account name"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_connection_string" {
  description = "Storage Account primary connection string"
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "storage_account_primary_blob_endpoint" {
  description = "Storage Account primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_container_pdfs" {
  description = "Storage container for PDFs"
  value       = azurerm_storage_container.pdfs.name
}

# Application Gateway
output "application_gateway_public_ip" {
  description = "Application Gateway Public IP"
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_fqdn" {
  description = "Application Gateway FQDN"
  value       = azurerm_public_ip.appgw.fqdn
}

output "gateway_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "gateway_health_endpoint" {
  description = "Gateway health check endpoint"
  value       = "http://${azurerm_public_ip.appgw.ip_address}/health"
}

# Data Factory
output "data_factory_name" {
  description = "Data Factory name"
  value       = azurerm_data_factory.main.name
}

output "data_factory_id" {
  description = "Data Factory ID"
  value       = azurerm_data_factory.main.id
}

# Monitoring
output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "Application Insights Instrumentation Key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights Connection String"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

# Instructions
output "next_steps" {
  description = "Next steps for deployment"
  value       = <<-EOT
    ========================================
    AZURE INFRASTRUCTURE DEPLOYED SUCCESSFULLY
    ========================================
    
    Next Steps:
    
    1. Configure kubectl to connect to AKS:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}
    
    2. Login to Azure Container Registry:
       az acr login --name ${azurerm_container_registry.main.name}
    
    3. Images already in ACR multiclouddrnicolas:
       multiclouddrnicolas.azurecr.io/multicloud-dr/api-gateway:latest
       multiclouddrnicolas.azurecr.io/multicloud-dr/data-processor:latest
       multiclouddrnicolas.azurecr.io/multicloud-dr/pdf-generator:latest
    
    4. Azure Container Instances deployed:
       - PDF Generator: ${azurerm_container_group.pdf_generator.ip_address}:8081
       - API Gateway: ${azurerm_container_group.api_gateway.ip_address}:8080
       - Data Processor: ${azurerm_container_group.data_processor.ip_address}:8082
    
    5. Configure AWS VPN Connection:
       - Use this IP in AWS Customer Gateway: ${azurerm_public_ip.vpn_gateway.ip_address}
       - Shared Key: (use the same value as in variables)
    
    6. Test the Application:
       - Application Gateway IP: ${azurerm_public_ip.appgw.ip_address}
       - Access: http://${azurerm_public_ip.appgw.ip_address}/api/health
    
    7. Monitor in Azure Portal:
       - Application Insights: ${azurerm_application_insights.main.name}
       - Log Analytics: ${azurerm_log_analytics_workspace.main.name}
    
    ========================================
  EOT
}

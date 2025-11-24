# Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Application Insights for microservices monitoring
resource "azurerm_application_insights" "main" {
  name                = "${var.project_name}-appinsights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = local.common_tags
}

# Azure Monitor Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${var.project_name}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "p0-action"

  tags = local.common_tags
}

# Metric Alert for AKS CPU usage (Deprecated - using ACI now)
# resource "azurerm_monitor_metric_alert" "aks_cpu" {
#   name                = "${var.project_name}-aks-cpu-alert"
#   resource_group_name = azurerm_resource_group.main.name
#   scopes              = [azurerm_kubernetes_cluster.main.id]
#   description         = "Alert when AKS CPU usage is high"
#   severity            = 2
#   frequency           = "PT1M"
#   window_size         = "PT5M"
#
#   criteria {
#     metric_namespace = "Microsoft.ContainerService/managedClusters"
#     metric_name      = "node_cpu_usage_percentage"
#     aggregation      = "Average"
#     operator         = "GreaterThan"
#     threshold        = 80
#   }
#
#   action {
#     action_group_id = azurerm_monitor_action_group.main.id
#   }
#
#   tags = local.common_tags
# }

# Metric Alert for CosmosDB Request Units
resource "azurerm_monitor_metric_alert" "cosmosdb_ru" {
  name                = "${var.project_name}-cosmosdb-ru-alert"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_cosmosdb_account.main.id]
  description         = "Alert when CosmosDB RU consumption is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "TotalRequestUnits"
    aggregation      = "Total"
    operator         = "GreaterThan"
    threshold        = 10000
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Diagnostic Settings for VPN Gateway
resource "azurerm_monitor_diagnostic_setting" "vpn" {
  name                       = "${var.project_name}-vpn-diagnostics"
  target_resource_id         = azurerm_virtual_network_gateway.vpn.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "GatewayDiagnosticLog"
  }

  enabled_log {
    category = "TunnelDiagnosticLog"
  }

  enabled_log {
    category = "RouteDiagnosticLog"
  }

  enabled_log {
    category = "IKEDiagnosticLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "appgw" {
  name                       = "${var.project_name}-appgw-diagnostics"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "${var.project_name}-storage-diagnostics"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  metric {
    category = "Transaction"
    enabled  = true
  }
}

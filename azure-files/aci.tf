# Azure Container Instances - Replicación de ECS sin Kubernetes
# Las imágenes deben estar en multiclouddrnicolas.azurecr.io

# Log Analytics Workspace para ACI
resource "azurerm_log_analytics_workspace" "aci" {
  name                = "${var.project_name}-aci-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# Container Group - PDF Generator
resource "azurerm_container_group" "pdf_generator" {
  name                = "${var.project_name}-pdf-generator"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]
  os_type             = "Linux"

  container {
    name   = "pdf-generator"
    image  = "${var.acr_name}.azurecr.io/multicloud-dr/pdf-generator:latest"
    cpu    = var.aci_cpu
    memory = var.aci_memory

    ports {
      port     = 8081
      protocol = "TCP"
    }

    environment_variables = {
      AZURE_REGION           = var.azure_location
      STORAGE_ACCOUNT_NAME   = azurerm_storage_account.main.name
      COSMOSDB_ENDPOINT      = azurerm_cosmosdb_account.main.endpoint
      COSMOSDB_DATABASE      = azurerm_cosmosdb_mongo_database.main.name
      STORAGE_CONTAINER_NAME = azurerm_storage_container.pdfs.name
      PYTHONUNBUFFERED       = "1"
    }

    secure_environment_variables = {
      COSMOSDB_KEY              = azurerm_cosmosdb_account.main.primary_key
      STORAGE_CONNECTION_STRING = azurerm_storage_account.main.primary_connection_string
    }

    liveness_probe {
      http_get {
        path   = "/health"
        port   = 8081
        scheme = "Http"
      }
      initial_delay_seconds = 30
      period_seconds        = 30
      timeout_seconds       = 5
      failure_threshold     = 3
    }

    readiness_probe {
      http_get {
        path   = "/health"
        port   = 8081
        scheme = "Http"
      }
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
  }

  image_registry_credential {
    server   = "${var.acr_name}.azurecr.io"
    username = var.acr_admin_username
    password = var.acr_admin_password
  }

  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.aci.workspace_id
      workspace_key = azurerm_log_analytics_workspace.aci.primary_shared_key
    }
  }

  tags = local.common_tags
}

# Container Group - API Gateway
resource "azurerm_container_group" "api_gateway" {
  name                = "${var.project_name}-api-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]
  os_type             = "Linux"

  container {
    name   = "api-gateway"
    image  = "${var.acr_name}.azurecr.io/multicloud-dr/api-gateway:latest"
    cpu    = var.aci_cpu
    memory = var.aci_memory

    ports {
      port     = 8080
      protocol = "TCP"
    }

    environment_variables = {
      AZURE_REGION      = var.azure_location
      COSMOSDB_ENDPOINT = azurerm_cosmosdb_account.main.endpoint
      COSMOSDB_DATABASE = azurerm_cosmosdb_mongo_database.main.name
      PYTHONUNBUFFERED  = "1"
    }

    secure_environment_variables = {
      COSMOSDB_KEY = azurerm_cosmosdb_account.main.primary_key
    }

    liveness_probe {
      http_get {
        path   = "/health"
        port   = 8080
        scheme = "Http"
      }
      initial_delay_seconds = 30
      period_seconds        = 30
      timeout_seconds       = 5
      failure_threshold     = 3
    }

    readiness_probe {
      http_get {
        path   = "/health"
        port   = 8080
        scheme = "Http"
      }
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
  }

  image_registry_credential {
    server   = "${var.acr_name}.azurecr.io"
    username = var.acr_admin_username
    password = var.acr_admin_password
  }

  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.aci.workspace_id
      workspace_key = azurerm_log_analytics_workspace.aci.primary_shared_key
    }
  }

  tags = local.common_tags
}

# Container Group - Data Processor
resource "azurerm_container_group" "data_processor" {
  name                = "${var.project_name}-data-processor"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]
  os_type             = "Linux"

  container {
    name   = "data-processor"
    image  = "${var.acr_name}.azurecr.io/multicloud-dr/data-processor:latest"
    cpu    = var.aci_cpu
    memory = var.aci_memory

    ports {
      port     = 8082
      protocol = "TCP"
    }

    environment_variables = {
      AZURE_REGION      = var.azure_location
      COSMOSDB_ENDPOINT = azurerm_cosmosdb_account.main.endpoint
      COSMOSDB_DATABASE = azurerm_cosmosdb_mongo_database.main.name
      PYTHONUNBUFFERED  = "1"
    }

    secure_environment_variables = {
      COSMOSDB_KEY = azurerm_cosmosdb_account.main.primary_key
    }

    liveness_probe {
      http_get {
        path   = "/health"
        port   = 8082
        scheme = "Http"
      }
      initial_delay_seconds = 30
      period_seconds        = 30
      timeout_seconds       = 5
      failure_threshold     = 3
    }

    readiness_probe {
      http_get {
        path   = "/health"
        port   = 8082
        scheme = "Http"
      }
      initial_delay_seconds = 10
      period_seconds        = 10
      timeout_seconds       = 5
      failure_threshold     = 3
    }
  }

  image_registry_credential {
    server   = "${var.acr_name}.azurecr.io"
    username = var.acr_admin_username
    password = var.acr_admin_password
  }

  diagnostics {
    log_analytics {
      workspace_id  = azurerm_log_analytics_workspace.aci.workspace_id
      workspace_key = azurerm_log_analytics_workspace.aci.primary_shared_key
    }
  }

  tags = local.common_tags
}

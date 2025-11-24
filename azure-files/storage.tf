# Storage Account for Blob Storage (equivalent to S3)
resource "azurerm_storage_account" "main" {
  name                     = "mcdrstg${substr(var.environment, 0, 4)}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication
  account_kind             = "StorageV2"
  
  # Enable versioning similar to S3
  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 90
    }
    
    container_delete_retention_policy {
      days = 90
    }
  }

  # Network rules
  network_rules {
    default_action             = "Deny"
    virtual_network_subnet_ids = [
      azurerm_subnet.aks.id,
      azurerm_subnet.database.id
    ]
    bypass = ["AzureServices"]
  }

  tags = local.common_tags
}

# Blob Container for PDF storage (equivalent to S3 bucket)
resource "azurerm_storage_container" "pdfs" {
  name                  = "pdfs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Blob Container for replicated data from AWS S3
resource "azurerm_storage_container" "s3_replica" {
  name                  = "s3-replica"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "${var.project_name}-storage-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.database.id

  private_service_connection {
    name                           = "${var.project_name}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  tags = local.common_tags
}

# Storage Account for Data Factory
resource "azurerm_storage_account" "datafactory" {
  name                     = "mcdrdf${substr(var.environment, 0, 4)}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  tags = local.common_tags
}

# Container for Data Factory staging
resource "azurerm_storage_container" "datafactory_staging" {
  name                  = "staging"
  storage_account_name  = azurerm_storage_account.datafactory.name
  container_access_type = "private"
}

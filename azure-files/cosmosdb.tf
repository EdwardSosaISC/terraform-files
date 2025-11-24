# Azure CosmosDB Account (with MongoDB API for compatibility)
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-cosmos-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  consistency_policy {
    consistency_level       = var.cosmosdb_consistency_level
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = azurerm_resource_group.main.location
    failover_priority = 0
  }

  geo_location {
    location          = var.azure_location_secondary
    failover_priority = 1
  }

  capabilities {
    name = "EnableMongo"
  }

  capabilities {
    name = "EnableServerless"
  }

  # Network rules
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = azurerm_subnet.database.id
  }

  virtual_network_rule {
    id = azurerm_subnet.aks.id
  }

  # Enable automatic failover
  automatic_failover_enabled = true

  # Enable multiple write locations for active-active
  multiple_write_locations_enabled = false

  # Backup policy - Continuous mode doesn't need interval/retention
  backup {
    type = "Continuous"
  }

  tags = local.common_tags
}

# CosmosDB MongoDB Database (equivalent to DynamoDB)
resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = "multicloud-dr-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
}

# Main Data Collection (equivalent to DynamoDB main table)
resource "azurerm_cosmosdb_mongo_collection" "main_data" {
  name                = "main-data"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["id", "timestamp"]
    unique = false
  }

  index {
    keys   = ["microservice", "timestamp"]
    unique = false
  }

  shard_key = "id"
}

# PDF Metadata Collection (equivalent to DynamoDB pdf metadata table)
resource "azurerm_cosmosdb_mongo_collection" "pdf_metadata" {
  name                = "pdf-metadata"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  database_name       = azurerm_cosmosdb_mongo_database.main.name

  index {
    keys   = ["_id"]
    unique = true
  }

  index {
    keys   = ["pdf_id", "created_at"]
    unique = false
  }

  index {
    keys   = ["user_id", "created_at"]
    unique = false
  }

  shard_key = "pdf_id"
}

# Private Endpoint for CosmosDB
resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "${var.project_name}-cosmosdb-pe"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.database.id

  private_service_connection {
    name                           = "${var.project_name}-cosmosdb-psc"
    private_connection_resource_id = azurerm_cosmosdb_account.main.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }

  tags = local.common_tags
}

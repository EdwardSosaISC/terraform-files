# Azure CosmosDB Account (with MongoDB API for compatibility)
resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.project_name}-cosmos-${var.environment}"
  location            = "centralus"  # CAMBIO: usar región con capacidad disponible
  resource_group_name = azurerm_resource_group.main.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  # Consistency policy - Ajustado para coincidir con Azure
  consistency_policy {
    consistency_level       = "Session"  # Azure usa Session por defecto
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  # Serverless solo soporta UNA región, sin Availability Zones
  geo_location {
    location          = "centralus"  # CAMBIO: misma región que el account
    failover_priority = 0
    zone_redundant    = false  # CRÍTICO: deshabilitar para evitar error de capacidad
  }

  capabilities {
    name = "EnableMongo"
  }

  # Comentar Serverless temporalmente si da problemas de capacidad
  # capabilities {
  #   name = "EnableServerless"
  # }

  # MongoDB API version
  mongo_server_version = "3.6"

  # Network rules
  is_virtual_network_filter_enabled = true
  public_network_access_enabled     = true

  virtual_network_rule {
    id                                   = azurerm_subnet.database.id
    ignore_missing_vnet_service_endpoint = false
  }

  virtual_network_rule {
    id                                   = azurerm_subnet.aci.id
    ignore_missing_vnet_service_endpoint = false
  }

  # Serverless no soporta automatic failover ni multiple writes
  automatic_failover_enabled       = false
  multiple_write_locations_enabled = false

  # Backup policy - Serverless usa backup periódico con Geo redundancy
  backup {
    type                = "Periodic"
    interval_in_minutes = 240
    retention_in_hours  = 8
    storage_redundancy  = "Geo"
  }

  # Analytical storage deshabilitado
  analytical_storage_enabled = false

  tags = local.common_tags
}

# CosmosDB MongoDB Database (equivalent to DynamoDB)
resource "azurerm_cosmosdb_mongo_database" "main" {
  name                = "multicloud-dr-db"
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.main.name
  
  # Throughput mínimo para modo Provisioned (no Serverless)
  throughput = 400  # Mínimo permitido, escalable manualmente
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
  
  # Sin throughput propio, usa el de la database
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
  
  # Sin throughput propio, usa el de la database
}

# Private Endpoint for CosmosDB
resource "azurerm_private_endpoint" "cosmosdb" {
  name                = "${var.project_name}-cosmosdb-pe"
  location            = azurerm_resource_group.main.location  # El endpoint SÍ debe estar en la VNet (eastus)
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

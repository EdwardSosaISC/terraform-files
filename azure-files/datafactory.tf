# Azure Data Factory
resource "azurerm_data_factory" "main" {
  name                = "${var.project_name}-adf-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Linked Service for AWS S3
resource "azurerm_data_factory_linked_service_web" "aws_s3" {
  count               = var.aws_access_key_id != "" ? 1 : 0
  name                = "AmazonS3LinkedService"
  data_factory_id     = azurerm_data_factory.main.id
  authentication_type = "Anonymous"
  url                 = "https://s3.${var.aws_region}.amazonaws.com"
  
  description = "Linked service to AWS S3 bucket"
}

# Linked Service for Azure Blob Storage (destination)
resource "azurerm_data_factory_linked_service_azure_blob_storage" "destination" {
  name              = "AzureBlobStorageLinkedService"
  data_factory_id   = azurerm_data_factory.main.id
  connection_string = azurerm_storage_account.main.primary_connection_string
}

# Dataset for AWS S3 source
resource "azurerm_data_factory_dataset_json" "s3_source" {
  count               = var.aws_access_key_id != "" ? 1 : 0
  name                = "S3SourceDataset"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_web.aws_s3[0].name

  azure_blob_storage_location {
    container = var.aws_s3_bucket_name
    path      = ""
    filename  = ""
  }
}

# Dataset for Azure Blob destination
resource "azurerm_data_factory_dataset_json" "blob_destination" {
  name                = "BlobDestinationDataset"
  data_factory_id     = azurerm_data_factory.main.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.destination.name

  azure_blob_storage_location {
    container = azurerm_storage_container.s3_replica.name
    path      = ""
    filename  = ""
  }
}

# Data Factory Pipeline for S3 to Blob replication
resource "azurerm_data_factory_pipeline" "s3_to_blob" {
  count           = var.aws_access_key_id != "" ? 1 : 0
  name            = "S3ToBlobReplicationPipeline"
  data_factory_id = azurerm_data_factory.main.id

  description = "Pipeline to replicate data from AWS S3 to Azure Blob Storage"

  activities_json = jsonencode([
    {
      name = "CopyFromS3ToBlob"
      type = "Copy"
      inputs = [
        {
          referenceName = azurerm_data_factory_dataset_json.s3_source[0].name
          type          = "DatasetReference"
        }
      ]
      outputs = [
        {
          referenceName = azurerm_data_factory_dataset_json.blob_destination.name
          type          = "DatasetReference"
        }
      ]
      typeProperties = {
        source = {
          type      = "JsonSource"
          recursive = true
        }
        sink = {
          type = "JsonSink"
        }
        enableStaging = false
      }
    }
  ])
}

# Data Factory Trigger (scheduled daily replication)
resource "azurerm_data_factory_trigger_schedule" "daily" {
  count           = var.aws_access_key_id != "" ? 1 : 0
  name            = "DailyS3Sync"
  data_factory_id = azurerm_data_factory.main.id
  pipeline_name   = azurerm_data_factory_pipeline.s3_to_blob[0].name

  frequency = "Day"
  interval  = 1
  
  schedule {
    hours   = [2]
    minutes = [0]
  }
}

# Role Assignment - Allow Data Factory to access Storage
resource "azurerm_role_assignment" "datafactory_storage" {
  principal_id                     = azurerm_data_factory.main.identity[0].principal_id
  role_definition_name             = "Storage Blob Data Contributor"
  scope                            = azurerm_storage_account.main.id
  skip_service_principal_aad_check = true
}

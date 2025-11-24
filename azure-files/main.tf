# Data sources
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# Local variables
locals {
  common_tags = merge(
    var.tags,
    {
      Location = var.azure_location
    }
  )
  
  microservices_config = {
    "pdf-generator" = {
      port = 8081
      path = "/pdf/*"
    }
    "api-gateway" = {
      port = 8080
      path = "/api/*"
    }
    "data-processor" = {
      port = 8082
      path = "/data/*"
    }
  }
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.azure_location

  tags = local.common_tags
}

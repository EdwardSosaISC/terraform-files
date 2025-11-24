# Public IP for Application Gateway
resource "azurerm_public_ip" "appgw" {
  name                = "${var.project_name}-appgw-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Application Gateway
resource "azurerm_application_gateway" "main" {
  name                = "${var.project_name}-appgw"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  # Frontend configuration
  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Backend address pools - Azure Container Instances
  backend_address_pool {
    name         = "pdf-generator-pool"
    ip_addresses = [azurerm_container_group.pdf_generator.ip_address]
  }

  backend_address_pool {
    name         = "api-gateway-pool"
    ip_addresses = [azurerm_container_group.api_gateway.ip_address]
  }

  backend_address_pool {
    name         = "data-processor-pool"
    ip_addresses = [azurerm_container_group.data_processor.ip_address]
  }

  # Backend HTTP settings
  backend_http_settings {
    name                  = "pdf-generator-http"
    cookie_based_affinity = "Disabled"
    port                  = 8081
    protocol              = "Http"
    request_timeout       = 60
    
    probe_name = "pdf-generator-probe"
  }

  backend_http_settings {
    name                  = "api-gateway-http"
    cookie_based_affinity = "Disabled"
    port                  = 8080
    protocol              = "Http"
    request_timeout       = 60
    
    probe_name = "api-gateway-probe"
  }

  backend_http_settings {
    name                  = "data-processor-http"
    cookie_based_affinity = "Disabled"
    port                  = 8082
    protocol              = "Http"
    request_timeout       = 60
    
    probe_name = "data-processor-probe"
  }

  # Health probes
  probe {
    name                = "pdf-generator-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    
    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                = "api-gateway-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    
    match {
      status_code = ["200-399"]
    }
  }

  probe {
    name                = "data-processor-probe"
    protocol            = "Http"
    path                = "/health"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    
    match {
      status_code = ["200-399"]
    }
  }

  # HTTP Listener
  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  # Request routing rules
  request_routing_rule {
    name                       = "pdf-generator-rule"
    rule_type                  = "PathBasedRouting"
    http_listener_name         = "http-listener"
    url_path_map_name          = "path-map"
    priority                   = 100
  }

  # URL path map
  url_path_map {
    name                               = "path-map"
    default_backend_address_pool_name  = "api-gateway-pool"
    default_backend_http_settings_name = "api-gateway-http"

    path_rule {
      name                       = "pdf-rule"
      paths                      = ["/pdf/*"]
      backend_address_pool_name  = "pdf-generator-pool"
      backend_http_settings_name = "pdf-generator-http"
    }

    path_rule {
      name                       = "api-rule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "api-gateway-pool"
      backend_http_settings_name = "api-gateway-http"
    }

    path_rule {
      name                       = "data-rule"
      paths                      = ["/data/*"]
      backend_address_pool_name  = "data-processor-pool"
      backend_http_settings_name = "data-processor-http"
    }
  }

  tags = local.common_tags

  depends_on = [
    azurerm_public_ip.appgw,
    azurerm_container_group.pdf_generator,
    azurerm_container_group.api_gateway,
    azurerm_container_group.data_processor
  ]
}

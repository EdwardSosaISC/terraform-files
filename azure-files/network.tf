# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = [var.vnet_cidr]

  tags = local.common_tags
}

# AKS Subnet (deprecated, keeping for compatibility)
resource "azurerm_subnet" "aks" {
  name                 = "${var.project_name}-aks-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aks_subnet_cidr]
}

# Azure Container Instances Subnet
resource "azurerm_subnet" "aci" {
  name                 = "${var.project_name}-aci-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.aci_subnet_cidr]
  
  delegation {
    name = "aci-delegation"
    
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Database/Replica Subnet
resource "azurerm_subnet" "database" {
  name                 = "${var.project_name}-db-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.db_subnet_cidr]
  
  service_endpoints = ["Microsoft.AzureCosmosDB", "Microsoft.Storage"]
}

# Application Gateway Subnet
resource "azurerm_subnet" "appgw" {
  name                 = "${var.project_name}-appgw-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.appgw_subnet_cidr]
}

# Gateway Subnet (for VPN)
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet" # Must be named exactly this
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.gateway_subnet_cidr]
}

# Network Security Group for AKS (deprecated, keeping for compatibility)
resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-aks-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTPS from Application Gateway
  security_rule {
    name                       = "Allow-AppGW-HTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.appgw_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow HTTP from Application Gateway
  security_rule {
    name                       = "Allow-AppGW-HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8081", "8082"]
    source_address_prefix      = var.appgw_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow traffic from AWS VPC
  security_rule {
    name                       = "Allow-AWS-VPC"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  # Allow internal VNet traffic
  security_rule {
    name                       = "Allow-VNet-Internal"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = local.common_tags
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Network Security Group for ACI
resource "azurerm_network_security_group" "aci" {
  name                = "${var.project_name}-aci-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow HTTP from Application Gateway
  security_rule {
    name                       = "Allow-AppGW-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "8081", "8082"]
    source_address_prefix      = var.appgw_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow traffic from AWS VPC
  security_rule {
    name                       = "Allow-AWS-VPC"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  # Allow internal VNet traffic
  security_rule {
    name                       = "Allow-VNet-Internal"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = local.common_tags
}

# Associate NSG with ACI subnet
resource "azurerm_subnet_network_security_group_association" "aci" {
  subnet_id                 = azurerm_subnet.aci.id
  network_security_group_id = azurerm_network_security_group.aci.id
}

# Network Security Group for Database
resource "azurerm_network_security_group" "database" {
  name                = "${var.project_name}-db-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow CosmosDB access from AKS
  security_rule {
    name                       = "Allow-AKS-CosmosDB"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "10250-10255"]
    source_address_prefix      = var.aks_subnet_cidr
    destination_address_prefix = "*"
  }

  # Allow traffic from AWS VPC
  security_rule {
    name                       = "Allow-AWS-VPC-DB"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "10250-10255"]
    source_address_prefix      = var.aws_vpc_cidr
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Associate NSG with Database subnet
resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database.id
}

# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway" {
  name                = "${var.project_name}-vpn-gateway-ip"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
}

# Virtual Network Gateway (VPN)
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${var.project_name}-vpn-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway.id
  }

  tags = local.common_tags
}

# Local Network Gateway (represents AWS VPN endpoint)
resource "azurerm_local_network_gateway" "aws" {
  count               = var.aws_vpn_gateway_ip != "" ? 1 : 0
  name                = "${var.project_name}-aws-local-gateway"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  gateway_address     = var.aws_vpn_gateway_ip
  address_space       = [var.aws_vpc_cidr]

  tags = local.common_tags
}

# VPN Connection to AWS
resource "azurerm_virtual_network_gateway_connection" "aws" {
  count               = var.aws_vpn_gateway_ip != "" ? 1 : 0
  name                = "${var.project_name}-azure-to-aws-vpn"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn.id
  local_network_gateway_id   = azurerm_local_network_gateway.aws[0].id

  shared_key = var.vpn_shared_key

  tags = local.common_tags
}

# Route Table for AWS traffic
resource "azurerm_route_table" "to_aws" {
  name                = "${var.project_name}-to-aws-rt"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  route {
    name                   = "to-aws-vpc"
    address_prefix         = var.aws_vpc_cidr
    next_hop_type          = "VirtualNetworkGateway"
  }

  tags = local.common_tags
}

# Associate route table with AKS subnet
resource "azurerm_subnet_route_table_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  route_table_id = azurerm_route_table.to_aws.id
}

# Associate route table with ACI subnet
resource "azurerm_subnet_route_table_association" "aci" {
  subnet_id      = azurerm_subnet.aci.id
  route_table_id = azurerm_route_table.to_aws.id
}

# Associate route table with Database subnet
resource "azurerm_subnet_route_table_association" "database" {
  subnet_id      = azurerm_subnet.database.id
  route_table_id = azurerm_route_table.to_aws.id
}

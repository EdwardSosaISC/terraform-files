# Azure Authentication
variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  default     = "cf358c01-372e-49c2-bc60-72ab0fb8d928"
}

variable "azure_tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  default     = "a1672a4e-def0-4aaf-bcf6-754ea59c5651"
}

# Region
variable "azure_location" {
  description = "Azure Region"
  type        = string
  default     = "eastus"
}

variable "azure_location_secondary" {
  description = "Azure Secondary Region for replication"
  type        = string
  default     = "westus2"
}

# Environment
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

# Project name
variable "project_name" {
  description = "Project name"
  type        = string
  default     = "multicloud-dr"
}

# Resource Group
variable "resource_group_name" {
  description = "Resource Group name"
  type        = string
  default     = "rg-multicloud-dr-prod"
}

# VNet CIDR
variable "vnet_cidr" {
  description = "VNet CIDR block"
  type        = string
  default     = "10.20.0.0/16"
}

# Subnet CIDRs
variable "aks_subnet_cidr" {
  description = "AKS subnet CIDR (deprecated, keeping for compatibility)"
  type        = string
  default     = "10.20.1.0/24"
}

variable "aci_subnet_cidr" {
  description = "Azure Container Instances subnet CIDR"
  type        = string
  default     = "10.20.1.0/24"
}

variable "db_subnet_cidr" {
  description = "Database subnet CIDR"
  type        = string
  default     = "10.20.2.0/24"
}

variable "gateway_subnet_cidr" {
  description = "Gateway subnet CIDR (for VPN)"
  type        = string
  default     = "10.20.255.0/27"
}

variable "appgw_subnet_cidr" {
  description = "Application Gateway subnet CIDR"
  type        = string
  default     = "10.20.3.0/24"
}

# AKS Configuration (deprecated, keeping for compatibility)
variable "aks_node_count" {
  description = "Number of AKS nodes"
  type        = number
  default     = 2
}

variable "aks_node_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.28"
}

# Azure Container Instances (ACI) Configuration
variable "aci_cpu" {
  description = "CPU cores for ACI containers"
  type        = number
  default     = 1
}

variable "aci_memory" {
  description = "Memory in GB for ACI containers"
  type        = number
  default     = 1.5
}

variable "acr_name" {
  description = "Azure Container Registry name (without .azurecr.io)"
  type        = string
  default     = "multiclouddrnicolas"
}

variable "acr_admin_username" {
  description = "ACR admin username"
  type        = string
  sensitive   = true
  default     = ""
}

variable "acr_admin_password" {
  description = "ACR admin password"
  type        = string
  sensitive   = true
  default     = ""
}

# Container Images (will be pushed to ACR)
variable "microservices" {
  description = "List of microservices"
  type        = list(string)
  default     = ["pdf-generator", "api-gateway", "data-processor"]
}

# CosmosDB Configuration
variable "cosmosdb_consistency_level" {
  description = "CosmosDB consistency level"
  type        = string
  default     = "Session"
}

variable "cosmosdb_max_throughput" {
  description = "CosmosDB max autoscale throughput"
  type        = number
  default     = 4000
}

# Storage Configuration
variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication" {
  description = "Storage account replication type"
  type        = string
  default     = "GRS" # Geo-Redundant Storage
}

# AWS VPN Configuration (for connectivity)
variable "aws_vpn_gateway_ip" {
  description = "AWS VPN Gateway public IP (to be provided after AWS deployment)"
  type        = string
  default     = "" # Will be filled after AWS deployment
}

variable "aws_vpc_cidr" {
  description = "AWS VPC CIDR for routing"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpn_shared_key" {
  description = "Shared key for VPN connection"
  type        = string
  sensitive   = true
  default     = "MySecureSharedKey123!" # Change in production
}

# AWS S3 Configuration (for Data Factory replication)
variable "aws_s3_bucket_name" {
  description = "AWS S3 bucket name to replicate from"
  type        = string
  default     = "multicloud-pdf-storage-dios-2025"
}

variable "aws_access_key_id" {
  description = "AWS Access Key ID for S3 access"
  type        = string
  sensitive   = true
  default     = "" # To be provided
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key for S3 access"
  type        = string
  sensitive   = true
  default     = "" # To be provided
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

# Tags
variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "multicloud-dr"
    Environment = "production"
    ManagedBy   = "Terraform"
    Cloud       = "Azure"
  }
}

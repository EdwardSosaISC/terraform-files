# Region
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
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

# ECR Image URIs
variable "pdf_generator_image" {
  description = "PDF Generator Docker image URI"
  type        = string
  default     = "503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/pdf-generator:latest"
}

variable "api_gateway_image" {
  description = "API Gateway Docker image URI"
  type        = string
  default     = "503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/api-gateway:latest"
}

variable "data_processor_image" {
  description = "Data Processor Docker image URI"
  type        = string
  default     = "503492729400.dkr.ecr.us-east-1.amazonaws.com/multicloud-dr/data-processor:latest"
}

# VPC CIDR
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

# Availability Zones
variable "availability_zones" {
  description = "Availability Zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# DynamoDB table names (SE RECREARÁN CON TERRAFORM)
variable "dynamodb_main_table" {
  description = "Main DynamoDB table name"
  type        = string
  default     = "multicloud-dr-data2"
}

variable "dynamodb_pdf_table" {
  description = "PDF metadata DynamoDB table name"
  type        = string
  default     = "multicloud-dr-pdf-metadata"
}

# S3 bucket name (SE RECREARÁ CON TERRAFORM)
variable "s3_bucket_name" {
  description = "S3 bucket name"
  type        = string
  default     = "multicloud-pdf-storage-dios-2025"
}

# ECS Task CPU and Memory
variable "task_cpu" {
  description = "ECS Task CPU units"
  type        = string
  default     = "512"  # 0.5 vCPU
}

variable "task_memory" {
  description = "ECS Task memory (MB)"
  type        = string
  default     = "1024"  # 1 GB
}

# Auto-scaling
variable "min_capacity" {
  description = "Minimum number of tasks"
  type        = number
  default     = 1
}

variable "max_capacity" {
  description = "Maximum number of tasks"
  type        = number
  default     = 4
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 2
}

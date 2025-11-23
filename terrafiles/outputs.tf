# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

# ECS Cluster
output "ecs_cluster_name" {
  description = "ECS Cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ECS Cluster ARN"
  value       = aws_ecs_cluster.main.arn
}

# Load Balancer
output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "Application Load Balancer URL"
  value       = "http://${aws_lb.main.dns_name}"
}

output "alb_arn" {
  description = "Application Load Balancer ARN"
  value       = aws_lb.main.arn
}

# DynamoDB Tables
output "dynamodb_main_table_name" {
  description = "Main DynamoDB table name"
  value       = aws_dynamodb_table.main.name
}

output "dynamodb_main_table_arn" {
  description = "Main DynamoDB table ARN"
  value       = aws_dynamodb_table.main.arn
}

output "dynamodb_pdf_table_name" {
  description = "PDF metadata DynamoDB table name"
  value       = aws_dynamodb_table.pdf_metadata.name
}

output "dynamodb_pdf_table_arn" {
  description = "PDF metadata DynamoDB table ARN"
  value       = aws_dynamodb_table.pdf_metadata.arn
}

# S3 Bucket
output "s3_bucket_name" {
  description = "S3 bucket name"
  value       = aws_s3_bucket.main.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.main.arn
}

# ECR Repositories
output "ecr_repositories" {
  description = "ECR repository URLs"
  value = {
    pdf_generator   = var.pdf_generator_image
    api_gateway     = var.api_gateway_image
    data_processor  = var.data_processor_image
  }
}

# Service URLs
output "service_endpoints" {
  description = "Service endpoints"
  value = {
    api_gateway     = "http://${aws_lb.main.dns_name}/api/info"
    pdf_generator   = "http://${aws_lb.main.dns_name}/pdf/generate"
    data_processor  = "http://${aws_lb.main.dns_name}/data/save"
    health_check    = "http://${aws_lb.main.dns_name}/health"
  }
}

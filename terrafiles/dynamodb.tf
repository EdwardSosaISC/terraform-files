# Main DynamoDB Table
resource "aws_dynamodb_table" "main" {
  name           = var.dynamodb_main_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"
  range_key      = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }

  attribute {
    name = "microservice"
    type = "S"
  }

  global_secondary_index {
    name            = "MicroserviceIndex"
    hash_key        = "microservice"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = var.dynamodb_main_table
    }
  )
}

# PDF Metadata DynamoDB Table
resource "aws_dynamodb_table" "pdf_metadata" {
  name           = var.dynamodb_pdf_table
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "pdf_id"
  range_key      = "created_at"

  attribute {
    name = "pdf_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "N"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "user_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = var.dynamodb_pdf_table
    }
  )
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack endpoint configuration. I would remove if I decided to go with real AWS.
provider "aws" {
  region                      = var.aws_region
  access_key                  = "fake"
  secret_key                  = "fake"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  # s3_use_path_style required for LocalStack, not needed for real AWS
  s3_use_path_style = true

  endpoints {
    s3       = "http://localhost:4566"
    dynamodb = "http://localhost:4566"
    iam      = "http://localhost:4566"
  }
}

locals {
  common_tags = {
    project     = var.project_name
    environment = var.environment
    managed_by  = "terraform"
  }
}

module "s3_state" {
  source        = "./modules/s3_bucket"
  environment   = var.environment
  project_name  = var.project_name
  bucket_suffix = "state"
  tags          = local.common_tags
}

module "s3_logs" {
  source        = "./modules/s3_bucket"
  environment   = var.environment
  project_name  = var.project_name
  bucket_suffix = "logs"
  tags          = local.common_tags
}
# DynamoDB table for Terraform state locking in production
resource "aws_dynamodb_table" "terraform_state_lock" {
  name         = "${var.project_name}-${var.environment}-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}

# IAM role representing a Lambda function with read access to the logs bucket
resource "aws_iam_role" "log_processor" {
  name = "${var.project_name}-${var.environment}-log-processor"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = local.common_tags
}

# Permission policy granting S3 read access to the role
resource "aws_iam_role_policy" "s3_read" {
  name = "${var.project_name}-${var.environment}-s3-read"
  role = aws_iam_role.log_processor.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          module.s3_logs.bucket_arn,
          "${module.s3_logs.bucket_arn}/*"
        ]
      }
    ]
  })
}
resource "aws_s3_bucket" "this" {
  bucket = "${var.project_name}-${var.environment}-${var.bucket_suffix}"
  tags   = var.tags
}

# Versioning is a separate resource since AWS provider v4
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SSE is a separate resource since AWS provider v4
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
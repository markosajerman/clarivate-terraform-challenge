output "s3_state_bucket_id" {
  description = "The name of the state S3 bucket"
  value       = module.s3_state.bucket_id
}

output "s3_state_bucket_arn" {
  description = "The ARN of the state S3 bucket"
  value       = module.s3_state.bucket_arn
}

output "s3_logs_bucket_id" {
  description = "The name of the logs S3 bucket"
  value       = module.s3_logs.bucket_id
}

output "s3_logs_bucket_arn" {
  description = "The ARN of the logs S3 bucket"
  value       = module.s3_logs.bucket_arn
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB state lock table"
  value       = aws_dynamodb_table.terraform_state_lock.name
}

output "iam_role_arn" {
  description = "The ARN of the IAM role for S3 read access"
  value       = aws_iam_role.s3_reader.arn
}
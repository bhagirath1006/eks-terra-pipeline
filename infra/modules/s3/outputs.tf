output "s3_bucket_name" {
  value       = data.aws_s3_bucket.terraform_state.id
  description = "Name of the S3 bucket for Terraform state"
}

output "s3_bucket_arn" {
  value       = data.aws_s3_bucket.terraform_state.arn
  description = "ARN of the S3 bucket for Terraform state"
}

output "dynamodb_table_name" {
  value       = data.aws_dynamodb_table.terraform_locks.name
  description = "Name of the DynamoDB table for state locking"
}

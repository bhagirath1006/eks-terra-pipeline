terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# Reference existing S3 bucket
data "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name
}

# Reference existing DynamoDB table for state locking
data "aws_dynamodb_table" "terraform_locks" {
  name = var.state_lock_table_name
}


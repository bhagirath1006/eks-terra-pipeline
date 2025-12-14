terraform {
  # Temporarily commented out - will be enabled after S3 bucket creation
  # backend "s3" {
  #   bucket         = "bhagirath-eks-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

# Note: The backend region MUST match var.region in main.tf
# Default region is us-east-1 for all resources (EKS, S3, DynamoDB)

terraform {
  # Configure the S3 backend for Terraform state
  # backend "s3" {
  #   bucket         = "bhagirath-eks-terraform-state"
  #   key            = "eks/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

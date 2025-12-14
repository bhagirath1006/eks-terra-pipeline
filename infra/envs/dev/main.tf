terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create S3 backend resources (state bucket and locking table)
module "s3_backend" {
  source = "../../modules/s3"
  state_bucket_name      = "bhagirath-eks-terraform-state"
  state_lock_table_name  = "terraform-state-lock"
}

module "vpc" {
  source = "../../modules/vpc"
  region = var.region
  name   = var.vpc_name
}

module "eks" {
  source = "../../modules/eks"
  cluster_name = var.cluster_name
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
}

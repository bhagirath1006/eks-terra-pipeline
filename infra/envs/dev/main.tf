terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider using the region variable
provider "aws" {
  region = var.region
}

# Create S3 backend resources
module "s3_backend" {
  source                = "../../modules/s3"
  state_bucket_name     = "bhagirath-eks-terraform-state"
  state_lock_table_name = "terraform-state-lock"
  region                = var.region
}

module "vpc" {
  source = "../../modules/vpc"
  region = var.region
  name   = var.vpc_name
}

module "eks" {
  source       = "../../modules/eks"
  cluster_name = var.cluster_name
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
}
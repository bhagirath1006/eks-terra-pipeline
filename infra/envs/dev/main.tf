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

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

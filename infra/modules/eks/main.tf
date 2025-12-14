// EKS module wrapper
variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"
  type        = list(string)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  eks_managed_node_groups = {
    default = {
      name = "default-node-group"
      
      desired_size = 1
      max_size     = 2
      min_size     = 1

      instance_types = ["t3.medium"]

      capacity_type = "ON_DEMAND"

      tags = {
        Environment = "dev"
      }
    }
  }

  manage_aws_auth = true

  tags = {
    Name        = var.cluster_name
    Environment = "dev"
  }
}

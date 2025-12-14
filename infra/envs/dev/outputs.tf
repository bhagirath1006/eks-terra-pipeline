output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC ID"
}

output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "EKS cluster version"
}

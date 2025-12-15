output "cluster_id" {
  value       = aws_eks_cluster.main.id
  description = "EKS cluster ID"
}

output "cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint"
}

output "cluster_ca_certificate" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "EKS cluster CA certificate"
  sensitive   = true
}

output "cluster_version" {
  value       = aws_eks_cluster.main.version
  description = "EKS cluster version"
}

output "cluster_arn" {
  value       = aws_eks_cluster.main.arn
  description = "EKS cluster ARN"
}

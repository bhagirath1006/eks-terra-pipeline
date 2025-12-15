variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "simple-vpc"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "simple-eks"
}

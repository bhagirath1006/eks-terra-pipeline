variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket for terraform state (create beforehand)"
  type        = string
  default     = "my-terraform-state-bucket"
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

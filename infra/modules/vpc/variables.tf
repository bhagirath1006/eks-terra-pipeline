variable "region" {
  description = "AWS region"
  type        = string
}

variable "name" {
  description = "Name of the VPC"
  type        = string
  default     = "simple-vpc"
}

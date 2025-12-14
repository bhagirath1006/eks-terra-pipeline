# Terraform Bootstrap

This directory contains the infrastructure needed to support Terraform remote state management.

## What it creates:
- S3 bucket for storing Terraform state files
- DynamoDB table for state locking
- Encryption and versioning enabled on S3

## How to use:

1. **Initialize and apply bootstrap (one-time setup):**
```bash
cd infra/bootstrap
terraform init
terraform plan
terraform apply
```

2. **After bootstrap is complete**, the S3 bucket and DynamoDB table will be ready for the main infrastructure in `infra/envs/dev/`

3. **Then initialize the dev environment:**
```bash
cd ../envs/dev
terraform init
terraform plan
terraform apply
```

## Notes:
- The S3 bucket name is hardcoded as `bhagirath-eks-terraform-state`
- DynamoDB table is named `terraform-state-lock`
- All resources are tagged for easy identification

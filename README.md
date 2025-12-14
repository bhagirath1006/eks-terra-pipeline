Minimal Working Terraform EKS Project (Module-based)
--------------------------------------------------

What's included:
- infra/modules/vpc (wrapper for terraform-aws-modules/vpc/aws)
- infra/modules/eks (wrapper for terraform-aws-modules/eks/aws)
- infra/envs/dev (root module that calls vpc + eks)
- simple k8s manifests in apps/k8s
- GitHub Actions workflows for CI (Terraform) and CD (kubectl apply)

IMPORTANT: Replace placeholders (S3 bucket name, AWS account ID, role ARNs)
before running. Create the S3 bucket and DynamoDB table for state backend manually.

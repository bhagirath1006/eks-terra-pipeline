# Deployment Steps

## 1. Create EKS Cluster (via CI Workflow)

Push changes to `infra/` folder to trigger the CI workflow:

```bash
git add infra/
git commit -m "Configure EKS cluster with Terraform"
git push origin main
```

**Monitor**: Go to GitHub Actions → `Terraform CI (Plan & Apply)` workflow
- Wait for `terraform apply` to complete successfully
- This will create:
  - VPC with public/private subnets
  - EKS cluster named `simple-eks`
  - EKS node group with t3.medium instances

## 2. Deploy Applications (via CD Workflow)

After CI completes successfully, push changes to `apps/k8s/` folder to trigger the CD workflow:

```bash
git add apps/
git commit -m "Deploy Kubernetes manifests"
git push origin main
```

**Monitor**: Go to GitHub Actions → `CD Deploy` workflow
- Wait for deployment to complete
- This will:
  - Update kubeconfig to connect to `simple-eks` cluster
  - Apply Kubernetes manifests (deployment, service, replicas)
  - Verify deployment status

## 3. Access the Application

After CD completes, get the LoadBalancer endpoint:

```bash
aws eks update-kubeconfig --region us-east-1 --name simple-eks
kubectl get services
# Copy the EXTERNAL-IP for the LoadBalancer service
```

## Troubleshooting

### Error: "No cluster found for name: simple-eks"
- **Cause**: EKS cluster hasn't been created yet
- **Solution**: Run CI workflow first (step 1 above)
- **Check**: Verify in AWS Console → EKS → Clusters

### Error: "ResourceNotFoundException" in CD workflow
- **Cause**: Cluster doesn't exist or name mismatch
- **Solution**: Verify cluster name is `simple-eks` in both:
  - `infra/envs/dev/terraform.tfvars` (cluster_name)
  - `.github/workflows/cd-deploy.yml` (CLUSTER_NAME env var)

### Error: "EntityAlreadyExists" in CI workflow
- **Cause**: Resources already created in AWS
- **Solution**: Either:
  - Use `terraform import` to import existing resources, OR
  - Delete resources manually from AWS and rerun, OR
  - Modify terraform code to use data sources (already done)

## Current Configuration

| Setting | Value |
|---------|-------|
| AWS Region | us-east-1 |
| Cluster Name | simple-eks |
| Node Instance Type | t3.medium |
| Desired Nodes | 1 |
| Max Nodes | 2 |
| Min Nodes | 1 |
| EKS Version | 1.29 |
| VPC CIDR | 10.0.0.0/16 |

## Files Modified
- `.github/workflows/ci-terraform.yml` - CI workflow fixed
- `.github/workflows/cd-deploy.yml` - Already correct
- `infra/modules/eks/main.tf` - Using data sources for IAM roles
- `infra/modules/s3/main.tf` - Using data sources for S3/DynamoDB
- `infra/envs/dev/terraform.tfvars` - Correct cluster name

All Terraform code has been validated and formatted. Ready for deployment!

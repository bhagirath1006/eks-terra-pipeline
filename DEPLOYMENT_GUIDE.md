# EKS Terraform Pipeline - Deployment & Testing Guide

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account Setup**
   - AWS CLI configured with appropriate credentials
   - S3 bucket for Terraform state (create manually)
   - DynamoDB table for state locking (create manually)

2. **GitHub Repository Setup**
   - Repository cloned locally
   - GitHub OIDC provider configured in AWS
   - Two IAM roles created:
     - `github-oidc-terraform` - for Terraform apply
     - `github-oidc-deployer` - for kubectl deployments

3. **Local Tools**
   - Terraform >= 1.5.0
   - AWS CLI >= 2.0
   - kubectl >= 1.29
   - Git

## Step 1: Configure Terraform Backend

Update `infra/envs/dev/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR-ACTUAL-BUCKET-NAME"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "YOUR-ACTUAL-TABLE-NAME"
    encrypt        = true
  }
}
```

## Step 2: Set GitHub Variables

Add these to GitHub repository settings (Settings > Variables):

- `AWS_REGION`: us-east-1 (or your preferred region)
- `AWS_ACCOUNT_ID`: Your AWS account ID

## Step 3: Update IAM Roles

Replace the ARNs in workflows with your actual IAM role ARNs:

- `.github/workflows/ci-terraform.yml` → `role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-oidc-terraform`
- `.github/workflows/cd-deploy.yml` → `role-to-assume: arn:aws:iam::YOUR-ACCOUNT-ID:role/github-oidc-deployer`

## Testing Locally

### Test Terraform Configuration

```bash
cd infra/envs/dev

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format check
terraform fmt -check -recursive

# Generate plan (dry-run)
terraform plan -out=tfplan

# Review the plan output
terraform show tfplan
```

### Test Kubernetes Manifests

```bash
# Validate YAML syntax
kubectl apply -f apps/k8s/ --dry-run=client --validate=true

# Check manifest validity
kubectl apply -f apps/k8s/deployment.yaml --dry-run=server
kubectl apply -f apps/k8s/service.yaml --dry-run=server
```

## Deployment Steps

### Option 1: Deploy via GitHub Actions (Recommended)

1. **Create and push a branch with infrastructure changes:**
   ```bash
   git checkout -b feat/deploy-eks
   git add infra/
   git commit -m "Deploy EKS infrastructure"
   git push origin feat/deploy-eks
   ```

2. **Create a Pull Request**
   - GitHub Actions will automatically run `terraform plan`
   - Review the plan output in the PR comments
   - Approve the PR

3. **Merge to main**
   - This triggers `terraform apply` automatically
   - EKS cluster creation begins (~15-20 minutes)

4. **Deploy applications:**
   ```bash
   git add apps/k8s/
   git commit -m "Deploy applications to EKS"
   git push origin main
   ```
   - GitHub Actions will apply the Kubernetes manifests

### Option 2: Manual Deployment (Testing)

```bash
# 1. Initialize Terraform
cd infra/envs/dev
terraform init

# 2. Create the infrastructure
terraform apply -auto-approve tfplan

# 3. Get cluster credentials
aws eks update-kubeconfig --name simple-eks --region us-east-1

# 4. Deploy applications
kubectl apply -f ../../apps/k8s/

# 5. Verify deployment
kubectl get deployments
kubectl get services
kubectl get pods
```

## Verification Checklist

After deployment, verify:

### Infrastructure (Terraform)

- [ ] EKS cluster created: `aws eks describe-cluster --name simple-eks`
- [ ] Node group active: `aws eks describe-nodegroup --cluster-name simple-eks --nodegroup-name default`
- [ ] VPC/Subnets created: `aws ec2 describe-vpcs | grep simple-vpc`
- [ ] Security groups configured correctly
- [ ] Terraform state stored in S3

### Kubernetes Cluster

```bash
# Check cluster connectivity
kubectl cluster-info

# Verify nodes are ready
kubectl get nodes
# Expected: 1-2 nodes in Ready state

# Check system pods
kubectl get pods -n kube-system
# Expected: coredns, aws-node, kube-proxy running
```

### Application Deployment

```bash
# Check deployments
kubectl get deployments
# Expected: deploy-app with 2 replicas

# Check pods
kubectl get pods -l app=deploy-app
# Expected: 2 pods in Running state

# Check services
kubectl get svc deploy-app
# Expected: LoadBalancer with external IP

# Test the application
EXTERNAL_IP=$(kubectl get svc deploy-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$EXTERNAL_IP
# Expected: Nginx default page
```

## Troubleshooting

### Terraform Issues

**Error: "backend initialization required"**
```bash
terraform init -upgrade
```

**Error: "invalid resource configuration"**
```bash
terraform validate
terraform fmt -recursive
```

### Kubernetes Issues

**Pods stuck in Pending:**
```bash
kubectl describe pods -l app=deploy-app
kubectl get events --sort-by='.lastTimestamp'
```

**Cannot access LoadBalancer:**
```bash
# Check security groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=simple-eks*"

# Check node security group ingress rules
aws ec2 authorize-security-group-ingress --group-id sg-xxxxx --protocol tcp --port 80 --cidr 0.0.0.0/0
```

### GitHub Actions Issues

**OIDC role assumption failed:**
- Verify AWS account ID in role ARN
- Check role trust policy includes GitHub OIDC provider
- Verify GitHub repository is allowed in trust policy

**Terraform apply fails:**
- Check AWS credentials via OIDC
- Verify S3 bucket and DynamoDB table exist
- Check IAM permissions on the role

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete -f apps/k8s/

# Delete AWS infrastructure
cd infra/envs/dev
terraform destroy -auto-approve
```

## Additional Resources

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [GitHub Actions OIDC Documentation](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)

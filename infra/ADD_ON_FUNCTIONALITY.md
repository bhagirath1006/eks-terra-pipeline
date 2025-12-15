# Add-On Functionality Guide

## Overview

This Terraform configuration now supports **conditional resource creation** through "add-on functionality" flags. This allows your infrastructure code to work seamlessly with:
- **First deployment**: Create all resources from scratch
- **Subsequent deployments**: Use existing resources without conflicts

## Conditional Variables

### 1. `create_backend_resources`
**Location**: [infra/envs/dev/variables.tf](infra/envs/dev/variables.tf)

Controls whether to create or reference:
- S3 bucket: `bhagirath-eks-terraform-state`
- DynamoDB table: `terraform-state-lock`

**Default**: `false` (uses existing resources)

When `false`:
- Uses `data.aws_s3_bucket` to reference the existing bucket
- Uses `data.aws_dynamodb_table` to reference the existing table

When `true`:
- Creates S3 bucket with versioning, encryption, and public access blocks
- Creates DynamoDB table with `prevent_destroy` lifecycle

### 2. `create_iam_roles`
**Location**: [infra/envs/dev/variables.tf](infra/envs/dev/variables.tf)

Controls whether to create or reference:
- EKS cluster role: `simple-eks-cluster-role`
- EKS node role: `simple-eks-node-role`

**Default**: `false` (uses existing resources)

When `false`:
- Uses `data.aws_iam_role` to reference existing roles
- No IAM policy attachments attempted

When `true`:
- Creates both IAM roles with proper trust policies
- Attaches required policies:
  - Cluster: `AmazonEKSClusterPolicy`
  - Node: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

## How It Works

### Conditional Logic Pattern

```hcl
# In EKS module (infra/modules/eks/main.tf)
data "aws_iam_role" "eks_cluster_role_existing" {
  count = var.create_iam_roles ? 0 : 1  # 0 if creating, 1 if referencing
  name  = "${var.cluster_name}-cluster-role"
}

resource "aws_iam_role" "eks_cluster_role" {
  count = var.create_iam_roles ? 1 : 0  # 1 if creating, 0 if skipping
  name  = "${var.cluster_name}-cluster-role"
  # ... rest of config
}

locals {
  cluster_role_arn = var.create_iam_roles ? 
    aws_iam_role.eks_cluster_role[0].arn : 
    data.aws_iam_role.eks_cluster_role_existing[0].arn
}
```

This pattern uses:
- **`count`** to conditionally create resources
- **`data` sources** to reference existing resources
- **`locals`** to choose between created or existing ARN

## Configuration

### Current Setup (terraform.tfvars)

```hcl
create_backend_resources = false  # Use existing S3 + DynamoDB
create_iam_roles = false          # Use existing IAM roles
region = "us-east-1"
vpc_name = "simple-vpc"
cluster_name = "simple-eks"
```

### Usage Scenarios

#### Scenario 1: Fresh Deployment (First Time)
If resources don't exist in AWS yet, set both to `true`:

```hcl
create_backend_resources = true  # Create S3 + DynamoDB
create_iam_roles = true          # Create IAM roles
```

Then:
```bash
cd infra/envs/dev
terraform init
terraform plan
terraform apply
```

#### Scenario 2: Add to Existing Infrastructure (Current State)
If resources already exist in AWS, set both to `false`:

```hcl
create_backend_resources = false  # Reference existing S3 + DynamoDB
create_iam_roles = false          # Reference existing IAM roles
```

Then:
```bash
cd infra/envs/dev
terraform init
terraform plan  # Should show only cluster and node group creation
terraform apply
```

#### Scenario 3: Selective Creation
Mix and match based on what exists:

```hcl
create_backend_resources = false  # S3 + DynamoDB already exist
create_iam_roles = true           # Create fresh IAM roles
```

## Resource Mapping

### S3 Module Resources

| Resource Type | Created When | Referenced When |
|---|---|---|
| `aws_s3_bucket` | `create_backend_resources=true` | `create_backend_resources=false` (data source) |
| `aws_s3_bucket_versioning` | `create_backend_resources=true` | N/A |
| `aws_s3_bucket_server_side_encryption_configuration` | `create_backend_resources=true` | N/A |
| `aws_s3_bucket_public_access_block` | `create_backend_resources=true` | N/A |
| `aws_dynamodb_table` | `create_backend_resources=true` | `create_backend_resources=false` (data source) |

### EKS Module Resources

| Resource Type | Created When | Referenced When |
|---|---|---|
| `aws_iam_role` (cluster) | `create_iam_roles=true` | `create_iam_roles=false` (data source) |
| `aws_iam_role` (node) | `create_iam_roles=true` | `create_iam_roles=false` (data source) |
| `aws_iam_role_policy_attachment` (4x) | `create_iam_roles=true` | N/A |
| `aws_eks_cluster` | Always created | Always created |
| `aws_eks_node_group` | Always created | Always created |

Resources always created (regardless of flags):
- VPC and subnets
- EKS cluster
- EKS node group

## Testing Your Configuration

### Step 1: Validate Syntax
```bash
cd infra/envs/dev
terraform fmt -check
terraform validate
```

### Step 2: Preview Changes
```bash
terraform plan
```

**Expected output** (with `create_backend_resources=false` and `create_iam_roles=false`):
```
Plan: 2 to add, 0 to change, 0 to destroy.
- aws_eks_cluster.main
- aws_eks_node_group.default
```

### Step 3: Apply Configuration
```bash
terraform apply
```

## Troubleshooting

### Error: "Error: resource doesn't exist"
**Cause**: `create_iam_roles=false` or `create_backend_resources=false` but resources don't exist

**Solution**: 
1. Check if resources exist in AWS:
   - S3 bucket: `bhagirath-eks-terraform-state`
   - DynamoDB table: `terraform-state-lock`
   - IAM roles: `simple-eks-cluster-role`, `simple-eks-node-role`

2. If they don't exist, set flags to `true`
3. If they exist but have different names, update the code to match

### Error: "Error: EntityAlreadyExists"
**Cause**: `create_iam_roles=true` or `create_backend_resources=true` but resources already exist

**Solution**: Set flags to `false` to use data sources instead

### Error: "Error: data source doesn't exist"
**Cause**: `create_iam_roles=false` but IAM roles don't exist in AWS

**Solution**: 
1. Verify role names match: `simple-eks-cluster-role`, `simple-eks-node-role`
2. Or set `create_iam_roles=true` to create them first

## Migration Path

### Moving from Manual Resources to Terraform State

1. **Current state**: Resources exist in AWS, not in Terraform state
2. **Goal**: Get Terraform to manage these resources

**Steps**:

```bash
# 1. Keep flags as false to reference existing resources
create_backend_resources = false
create_iam_roles = false

# 2. Run terraform init (uses local state initially)
terraform init

# 3. Run terraform plan (shows cluster and node group creation)
terraform plan

# 4. Apply to create cluster and node group
terraform apply

# 5. Once infrastructure is stable, enable S3 backend
# Uncomment backend.tf configuration:
# terraform {
#   backend "s3" {
#     bucket         = "bhagirath-eks-terraform-state"
#     key            = "eks/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }

# 6. Migrate state to S3
terraform init  # Will prompt to copy state to S3
# Type "yes" to confirm

# 7. Verify state is now remote
terraform state list
```

## Real-World Example

### Your Current Setup

Your AWS account has:
- ✅ S3 bucket: `bhagirath-eks-terraform-state` (exists)
- ✅ DynamoDB table: `terraform-state-lock` (exists)
- ✅ IAM role: `simple-eks-cluster-role` (exists)
- ✅ IAM role: `simple-eks-node-role` (exists)
- ❌ EKS cluster: doesn't exist yet
- ❌ EKS node group: doesn't exist yet

**Configuration**:
```hcl
create_backend_resources = false  # Don't recreate existing S3/DynamoDB
create_iam_roles = false          # Don't recreate existing IAM roles
```

**Result**:
```bash
terraform plan
# Plan: 2 to add
# + aws_eks_cluster.main
# + aws_eks_node_group.default
```

This creates only the EKS resources while referencing the existing S3, DynamoDB, and IAM resources!

## Best Practices

1. **Always run `terraform plan` before apply**
   - Review what will be created/modified
   - Catch configuration mistakes early

2. **Use `terraform.tfvars` for environment-specific settings**
   - Keep defaults in `variables.tf`
   - Override in `terraform.tfvars`

3. **Enable S3 backend for team collaboration**
   - Prevents concurrent modifications
   - Adds DynamoDB locking
   - Centralizes state management

4. **Tag all resources consistently**
   - Aids cost allocation
   - Simplifies resource discovery
   - Supports automation

5. **Use data sources for read-only references**
   - Less risky than managing created resources
   - Prevents accidental deletions
   - Allows testing without recreating

## Next Steps

1. ✅ Test with current configuration (`create_backend_resources=false`, `create_iam_roles=false`)
2. ✅ Verify EKS cluster and node group are created successfully
3. ✅ Once stable, enable S3 backend for remote state management
4. ✅ Monitor GitHub Actions CI/CD pipeline for automated deployments
5. ✅ Deploy applications via CD workflow

---

**Need help?** Check the [DEPLOYMENT_GUIDE.md](../../DEPLOYMENT_GUIDE.md) for full setup instructions.

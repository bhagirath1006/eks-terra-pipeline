#!/bin/bash
# Add IAM user to EKS aws-auth ConfigMap
# Usage: ./add-user-to-eks.sh <cluster-name> <iam-user-arn> <username>

CLUSTER_NAME="simple-eks"
REGION="us-east-1"
IAM_USER_ARN="arn:aws:iam::360477615168:user/eks-terra"
USERNAME="eks-terra"

echo "Adding IAM user to aws-auth ConfigMap..."
echo "Cluster: $CLUSTER_NAME"
echo "IAM User: $IAM_USER_ARN"

# Create the mapping
ROLE_ARN=$(aws iam get-user --user-name eks-terra --query 'User.Arn' --output text)

# Get current ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml > /tmp/aws-auth-backup.yaml
echo "Backup created: /tmp/aws-auth-backup.yaml"

# Add user to mapUsers section
kubectl patch configmap aws-auth -n kube-system --type merge -p "{\"data\":{\"mapUsers\":\"$(kubectl get configmap aws-auth -n kube-system -o jsonpath='{.data.mapUsers}' | sed "s/$/\\n  - userarn: $ROLE_ARN\\n    username: $USERNAME\\n    groups:\\n      - system:masters/")\"}}"

echo "User added successfully!"
echo "Verify with: kubectl auth can-i get nodes --as=eks-terra"

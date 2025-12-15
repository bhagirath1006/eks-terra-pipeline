# Add IAM users/roles to EKS aws-auth ConfigMap
# This allows users and GitHub Actions to access the cluster

data "aws_caller_identity" "current" {}

locals {
  aws_auth_configmap_data = {
    mapRoles = yamlencode(concat(
      [
        {
          rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/simple-eks-cluster-role"
          username = "eks-admin"
          groups   = ["system:masters"]
        }
      ],
      var.map_roles
    ))
    mapUsers = yamlencode(concat(
      [
        {
          userarn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/eks-terra"
          username = "eks-terra"
          groups   = ["system:masters"]
        }
      ],
      var.map_users
    ))
  }
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = local.aws_auth_configmap_data
}

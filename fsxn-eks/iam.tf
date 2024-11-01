# EKS Cluster IAM Role
resource "aws_iam_role" "eks_cluster_iam" {
  name = "eks-${terraform.workspace}-cluster-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_iam.name
}

# EKS Node IAM Role
resource "aws_iam_role" "eks_node" {
  name = "eks-${terraform.workspace}-worker-role"

  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_node.name
}

# EKS Trident-CSI IAM Role
resource "aws_iam_role" "eks_trident_csi" {
  name = "eks-${terraform.workspace}-trident-csi-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": aws_iam_openid_connect_provider.cluster.arn
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "sts.amazonaws.com",
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "system:serviceaccount:trident:trident-controller"
                }
            }
        },
        {
            "Sid": "ExplicitSelfRoleAssumption",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "ArnLike": {
                    "aws:PrincipalArn": "arn:aws:iam::aws:role/eks-${terraform.workspace}-trident-csi-role"
                }
            }
        }
    ]
})
}
resource "aws_iam_policy" "eks_trident_csi" {
  name = "eks-${terraform.workspace}-trident-csi-policy"
  description = "IAM policy for the Trident CSI that allows it to make calls to FSXN"

  policy = jsonencode({
    "Statement": [
        {
            "Action": [
                "fsx:DescribeFileSystems",
                "fsx:DescribeVolumes",
                "fsx:CreateVolume",
                "fsx:RestoreVolumeFromSnapshot",
                "fsx:DescribeStorageVirtualMachines",
                "fsx:UntagResource",
                "fsx:UpdateVolume",
                "fsx:TagResource",
                "fsx:DeleteVolume"
            ],
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Action": "secretsmanager:GetSecretValue",
            "Effect": "Allow",
            "Resource": [
                "${aws_secretsmanager_secret.fsx_password.arn}",
                "${aws_secretsmanager_secret.svm_password.arn}"
            ]
        }
    ],
    "Version": "2012-10-17"
})
}
resource "aws_iam_role_policy_attachment" "AmazonTridentCSIDriverRoleAttachment" {
  policy_arn = aws_iam_policy.eks_trident_csi.arn
  role       = aws_iam_role.eks_trident_csi.name
}

# EKS EBS-CSI IAM Role
resource "aws_iam_role" "eks_ebs_csi" {
  name = "eks-${terraform.workspace}-ebs-csi-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": aws_iam_openid_connect_provider.cluster.arn
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "sts.amazonaws.com",
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "system:serviceaccount:kube-system:ebs-csi-controller-sa"
                }
            }
        }
    ]
})
}
resource "aws_iam_role_policy_attachment" "AmazonEBSCSIDriverRoleAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks_ebs_csi.name
}

# EKS EFS-CSI IAM Role
resource "aws_iam_role" "eks_efs_csi" {
  name = "eks-${terraform.workspace}-efs-csi-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": aws_iam_openid_connect_provider.cluster.arn
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "sts.amazonaws.com",
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "system:serviceaccount:kube-system:efs-csi-*"
                }
            }
        }
    ]
})
}
resource "aws_iam_role_policy_attachment" "AmazonEFSCSIDriverRoleAttachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
  role       = aws_iam_role.eks_efs_csi.name
}


# Data source for IAM Policy
data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.1/docs/install/iam_policy.json"

  request_headers = {
    Accept = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

# EKS Load Balancer IAM Policy
resource "aws_iam_policy" "eks_lb" {
  name = "eks-${terraform.workspace}-lb-policy"
  description = "IAM policy for the AWS Load Balancer Controller that allows it to make calls to AWS APIs on our behalf"

  policy = data.http.iam_policy.response_body
}

# EKS Load Balancer IAM Role
resource "aws_iam_role" "eks_lb" {
  name = "eks-${terraform.workspace}-lb-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": aws_iam_openid_connect_provider.cluster.arn
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:aud", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "sts.amazonaws.com",
                    format("oidc.eks.${var.aws_region}.amazonaws.com/id/%s:sub", split("/", aws_iam_openid_connect_provider.cluster.arn)[3]): "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "AWSLoadBalancerControllerIAMPolicy" {
  policy_arn = aws_iam_policy.eks_lb.arn
  role       = aws_iam_role.eks_lb.name
}

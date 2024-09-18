# EKS Cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-${terraform.workspace}-cluster"
  role_arn = aws_iam_role.eks_cluster_iam.arn
  version  = var.eks_kubernetes_version

  vpc_config {
    subnet_ids              = flatten([aws_subnet.eks_public[*].id, aws_subnet.eks_private[*].id])
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.authorized_networks[*].cidr_block
  }

  tags = {
    Env  = "eks-${terraform.workspace}",
    Name = "eks-${terraform.workspace}-cluster"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy
  ]
}

# EKS Cluster Security Group
resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-${terraform.workspace}-cluster-sg"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.eks_vpc.id

  tags = {
    Env  = "eks-${terraform.workspace}",
    Name = "eks-${terraform.workspace}-cluster-sg"
  }
}

# EKS Cluster security group rules
resource "aws_security_group_rule" "eks_cluster_inbound" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks_cluster_outbound" {
  description              = "Allow cluster API Server to communicate with the worker nodes"
  from_port                = 1024
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  to_port                  = 65535
  type                     = "egress"
}


# EKS Node Groups
resource "aws_eks_node_group" "eks_ng" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${terraform.workspace}-node-group"
  node_role_arn   = aws_iam_role.eks_node.arn
  subnet_ids      = aws_subnet.eks_private[*].id

  scaling_config {
    desired_size = var.eks_node_count
    max_size     = var.eks_node_max
    min_size     = var.eks_node_min
  }

  ami_type       = "AL2_x86_64"
  capacity_type  = "ON_DEMAND"
  #disk_size      = 20
  instance_types = [var.eks_instance_type]

  launch_template {
    name = aws_launch_template.eks_ng_lt.name
    version = aws_launch_template.eks_ng_lt.latest_version
  }

  tags = {
    Env  = "eks-${terraform.workspace}",
    Name = "eks-${terraform.workspace}-node-group"
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKSVPCResourceController,
  ]
}

# User data / launch template for node group
resource "aws_launch_template" "eks_ng_lt" {
  name = "${terraform.workspace}-launch-template"
  user_data = data.cloudinit_config.cloudinit.rendered
}
data "cloudinit_config" "cloudinit" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = file("scripts/iscsi.sh")
  }
}

# EKS Node Security Group
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-${terraform.workspace}-nodes-sg"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.eks_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env                                                        = "eks-${terraform.workspace}",
    Name                                                       = "${terraform.workspace}-node-sg",
    "kubernetes.io/cluster/eks-${terraform.workspace}-cluster" = "owned"
  }
}

resource "aws_security_group_rule" "eks_nodes_internal" {
  description              = "Allow nodes to communicate with each other"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_nodes_sg.id
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "-1"
}

resource "aws_security_group_rule" "eks_nodes_cluster_inbound" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  security_group_id        = aws_security_group.eks_nodes_sg.id
  source_security_group_id = aws_security_group.eks_cluster_sg.id
  type                     = "ingress"
  from_port                = 1025
  to_port                  = 65535
  protocol                 = "tcp"
}


# ADD-ONS
resource "aws_eks_addon" "addons" {
  for_each                 = { for addon in var.eks_addons : addon.name => addon }
  cluster_name             = aws_eks_cluster.eks_cluster.id
  addon_name               = each.value.name
  addon_version            = each.value.version
  service_account_role_arn = each.value.name != "netapp_trident-operator" ? aws_iam_role.eks_node.arn : null

  configuration_values = each.value.name != "netapp_trident-operator" ? null : jsonencode({
    cloudIdentity = "'eks.amazonaws.com/role-arn: ${aws_iam_role.eks_trident_csi.arn}'"
  })

  tags = {
    Env  = "eks-${terraform.workspace}",
    Name = "eks-${terraform.workspace}-${each.value.name}"
  }
}
data "external" "thumbprint" {
  program = [format("%s/scripts/get_thumbprint.sh", path.module), var.aws_region]
}
## OIDC config
resource "aws_iam_openid_connect_provider" "cluster" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.external.thumbprint.result.thumbprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# Storage Class Setup
resource "terraform_data" "storage-class-setup" {
  depends_on = [aws_eks_addon.addons]
  triggers_replace = [
    aws_eks_cluster.eks_cluster.arn
  ]
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/storage_class_setup.sh"
    environment = {
      aws_region         = var.aws_region
      eks_cluster_name   = aws_eks_cluster.eks_cluster.name
      eks_lb_arn         = aws_iam_role.eks_lb.arn
      eks_svm_ip         = join("", aws_fsx_ontap_file_system.eksfs.endpoints[0].management[0].ip_addresses)
      eks_svm_name       = aws_fsx_ontap_storage_virtual_machine.ekssvm.name
      fsx_filesystem_id  = aws_fsx_ontap_file_system.eksfs.id
      svm_password       = aws_secretsmanager_secret.svm_password.arn
      vscrd_release      = var.vscrd_release
    }
  }
}

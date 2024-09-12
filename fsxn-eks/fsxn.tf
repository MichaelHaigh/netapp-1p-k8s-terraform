resource "random_string" "fsx_password" {
  length           = 8
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  special          = true
  override_special = "!"
}

resource "random_string" "svm_password" {
  length           = 8
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
  min_upper        = 1
  numeric          = true
  special          = true
  override_special = "!"
}

resource "aws_secretsmanager_secret" "fsx_password" {
  name        = "eks-${terraform.workspace}-fsxn"
  description = "EKS ${terraform.workspace} FSxN Password"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "fsx_password" {
  secret_id     = aws_secretsmanager_secret.fsx_password.id
  secret_string = jsonencode({
    username = "fsxadmin"
    password = "${random_string.fsx_password.result}"
  })
}

resource "aws_secretsmanager_secret" "svm_password" {
  name        = "eks-${terraform.workspace}-svm"
  description = "EKS ${terraform.workspace} SVM Password"

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "svm_password" {
  secret_id     = aws_secretsmanager_secret.svm_password.id
  secret_string = jsonencode({
    username = "vsadmin"
    password = "${random_string.svm_password.result}"
  })
}

resource "aws_fsx_ontap_file_system" "eksfs" {
  storage_capacity    = 2048
  subnet_ids          = aws_subnet.eks_private[*].id
  deployment_type     = "MULTI_AZ_1"
  throughput_capacity = 512
  preferred_subnet_id = aws_subnet.eks_private[0].id
  security_group_ids  = [aws_security_group.fsxn_sg.id]
  fsx_admin_password = random_string.fsx_password.result
  route_table_ids    = [aws_vpc.eks_vpc.default_route_table_id]
  tags = {
    Env    = "eks-${terraform.workspace}",
    Name   = "eks-${terraform.workspace}-fsxn"
  }
}

resource "aws_fsx_ontap_storage_virtual_machine" "ekssvm" {
  file_system_id     = aws_fsx_ontap_file_system.eksfs.id
  name               = "eks-${terraform.workspace}-svm"
  svm_admin_password = random_string.svm_password.result

  tags = {
    Env    = "eks-${terraform.workspace}",
    Name   = "eks-${terraform.workspace}-svm"
  }
}

resource "aws_security_group" "fsxn_sg" {
  name_prefix = "security group for fsxn access"
  vpc_id      = aws_vpc.eks_vpc.id
  tags = {
    Env    = "eks-${terraform.workspace}",
    Name   = "eks-${terraform.workspace}-fsxn-sg"
  }
}

resource "aws_security_group_rule" "fsxn_sg_inbound" {
  description       = "allow inbound traffic to eks"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.fsxn_sg.id
  type              = "ingress"
  cidr_blocks       = [var.eks_vpc_cidr]
}

resource "aws_security_group_rule" "fsxn_sg_outbound" {
  description       = "allow outbound traffic to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.fsxn_sg.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

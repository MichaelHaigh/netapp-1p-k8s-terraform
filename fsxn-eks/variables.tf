# AWS Settings
variable "aws_region" {
  type        = string
  description = "The AWS Region"
}
variable "aws_cred_file" {
  type        = string
  description = "The file location containing a json of the AWS credentials"
}
variable "availability_zones_count" {
  type        = string
  description = "The number of availability zones to deploy into"
}

# VPC Settings
variable "eks_vpc_cidr" {
  type        = string
  description = "The CIDR range for the VPC"
}
variable "eks_public_subnet_cidrs" {
  type        = list
  description = "A list of CIDR ranges for the public subnets, length must match 'availability_zones_count'"
}
variable "eks_private_subnet_cidrs" {
  type        = list
  description = "A list of CIDR ranges for the private subnets, length must match 'availability_zones_count'"
}

# EKS Settings
variable "eks_kubernetes_version" {
  type        = string
  description = "The Kubernetes version for the EKS cluster"
}
variable "eks_node_count" {
  type        = number
  description = "The default number of nodes in the node pool"
}
variable "eks_node_min" {
  type        = number
  description = "The minimum number of nodes in the node pool"
}
variable "eks_node_max" {
  type        = number
  description = "The maximum number of nodes in the node pool"
}
variable "eks_instance_type" {
  type        = string
  description = "The EC2 instance size/type"
}
variable "eks_addons" {
  type = list(object({
    name    = string
    version = string
  }))
  description = "A list of addon names and versions to install"
}

# Authorized Networks
variable "authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access."
  default     = []
}

# Outputs
variable "vscrd_release" {
  type        = string
  description = "The volume snapshot CRDs github release URL"
}
variable "ebscsi_release" {
  type        = string
  description = "The EBS-CSI driver github release URL"
}

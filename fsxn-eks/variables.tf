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
variable "creator_tag" {
  type        = string
  description = "The value to apply to the 'creator' key tag"
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

# FSxN Settings
variable "fsxn_storage_capacity" {
  type        = number
  description = "The storage capacity (in GiB) of the file system"
}
variable "fsxn_throughput_capacity" {
  type        = number
  description = "The throughput capacity (in MBps) for the file system. Valid values are 128, 256, 512, 1024, 2048, and 4096"
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

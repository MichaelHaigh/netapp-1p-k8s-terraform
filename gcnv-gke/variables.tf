# GCP Settings
variable "sa_creds" {
  type        = string
  description = "The Service Account json file path on local machine"
}
variable "gcp_sa" {
  type        = string
  description = "The name of the GCP Service Account"
}
variable "gcp_project" {
  type        = string
  description = "The GCP Project name"
}
variable "gcp_project_number" {
  type        = string
  description = "The GCP Project number"
}
variable "gcp_region" {
  type        = string
  description = "The GCP Region"
}
variable "gcp_zones" {
  type        = list(string)
  description = "A list of the GCP Zone(s)"
}
variable "creator_label" {
  type        = string
  description = "The value to apply to the 'creator' key label"
}

# VPC Settings
variable "gke_subnetwork_cidr" {
  type        = string
  description = "The subnetwork CIDR for the GKE cluster"
}
variable "gke_ip_range_control" {
  type        = string
  description = "The CIDR IP range for the control plane"
}
variable "gke_ip_range_services" {
  type        = string
  description = "The CIDR IP range for the services"
}
variable "gke_ip_range_pods" {
  type        = string
  description = "The CIDR IP range for the pods"
}

# GKE Cluster Settings
variable "gke_kubernetes_version" {
  type        = string
  description = "The Kubernetes version for the GKE cluster"
}
variable "gke_private_cluster" {
  type        = bool
  description = "Whether the cluster is private or not"
}
variable "gke_trident_version" {
  type        = string
  description = "The trident version to use for the output commands"
}

# Node Pool Settings
variable "gke_machine_type" {
  type        = string
  description = "The machine type for the default node pool"
}
variable "gke_image_type" {
  type        = string
  description = "The image_type of the node pool machines"
}
variable "gke_initial_node_count" {
  type        = number
  description = "The initial number of nodes (per gcp_region) in the default pool"
}
variable "gke_min_node_count" {
  type        = number
  description = "The minimum number of nodes (per gcp_region) in the default pool"
}
variable "gke_max_node_count" {
  type        = number
  description = "The maximum number of nodes (per gcp_region) in the default pool"
}

# GCNV Settings
variable "gcnv_service_level" {
  type        = string
  description = "The GCNV Service Level (should be one of flex, standard, premium, extreme)"

  validation {
    condition     = contains(["flex", "standard", "premium", "extreme"], var.gcnv_service_level)
    error_message = "Valid values for gcnv_service_level: (flex, standard, premium, extreme)"
  }
}
variable "gcnv_pool_capacity" {
  type        = string
  description = "The GCNV storage pool capacity in GiB"
}

# Authorized Networks
variable "authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access."
  default     = []
}

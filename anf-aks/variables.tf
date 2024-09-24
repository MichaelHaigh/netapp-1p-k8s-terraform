# Azure Settings
variable "sp_creds" {
  type        = string
  description = "The file path containing the service principal credentials"
}
variable "azr_region" {
  type        = string
  description = "The Azure region"
}
variable "creator_tag" {
  type        = string
  description = "The value to apply to the 'creator' key tag"
}

# VNet Settings
variable "aks_vnet_cidr" {
  type        = string
  description = "The CIDR IP range for the VNet"
}
variable "aks_vnet_dns_ip" {
  type        = string
  description = "The DNS IP for the VNet"
}
variable "aks_nodepool_cidr" {
  type        = string
  description = "The CIDR IP range for the nodepool VMs"
}
variable "aks_anf_cidr" {
  type        = string
  description = "The CIDR IP range for the ANF subnet"
}
variable "aks_services_cidr" {
  type        = string
  description = "The CIDR IP range for the services"
}
variable "aks_services_dns_ip" {
  type        = string
  description = "The IP of the DNS Service, must be within the aks_services_cidr CIDR"
}
variable "aks_pods_cidr" {
  type        = string
  description = "The CIDR IP range for the pods"
}

# AKS Cluster Settings
variable "aks_kubernetes_version" {
  type        = string
  description = "The Kubernetes version of the AKS cluster"
}
variable "aks_trident_version" {
  type        = string
  description = "The trident version to use for the output commands"
}

# Node Pool Settings
variable "aks_node_count" {
  type        = number
  description = "The initial node count for the default_node_pool"
}
variable "aks_image_size" {
  type        = string
  description = "The VM / image size for the default_node_pool"
}
variable "aks_os_disk_size_gb" {
  type        = string
  description = "The VM / image OS disk size for the default_node_pool"
  default     = 30
}

# ANF Settings
variable "anf_service_level" {
  type        = string
  description = "The ANF Storage Class service level (must be one of Standard, Premium, Ultra)"

  validation {
    condition     = contains(["Standard", "Premium", "Ultra"], var.anf_service_level)
    error_message = "Valid values for anf_service_level: (Standard, Premium, Ultra)"
  }
}
variable "anf_pool_size" {
  type        = number
  description = "The size of the ANF capacity pool (in TiB)"
}


# Authorized Networks
variable "authorized_networks" {
  type        = list(object({ cidr_block = string, display_name = string }))
  description = "List of master authorized networks. If none are provided, disallow external access."
  default     = []
}

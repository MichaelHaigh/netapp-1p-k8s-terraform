# Azure Settings
sp_creds    = "~/.azure/azure-sp-tme-demo2-terraform.json"
azr_region  = "eastus"
creator_tag = "mhaigh"

# VNet Settings
aks_vnet_cidr       = "10.20.0.0/22"
aks_vnet_dns_ip     = "10.20.3.254"   # must be w/in vnet
aks_nodepool_cidr   = "10.20.0.0/23"  # must be w/in vnet
aks_anf_cidr        = "10.20.2.0/24"  # must be w/in vnet
aks_services_cidr   = "172.16.0.0/16" # must not be w/in vnet
aks_services_dns_ip = "172.16.0.10"   # must be w/in services
aks_pods_cidr       = "172.18.0.0/16" # must not be w/in vnet

# AKS Cluster Settings
aks_kubernetes_version  = "1.29.7"
aks_trident_version     = "24.06.1"

# Node Pool Settings
aks_node_count = 2
aks_image_size = "Standard_D4s_v3"

# ANF Settings
anf_service_level = "Standard"
anf_pool_size     = 4

# Authorized Networks
authorized_networks = [
  {
    cidr_block   = "198.51.100.0/24"
    display_name = "company_range"
  },
  {
    cidr_block   = "203.0.113.30/32"
    display_name = "home_address"
  },
]

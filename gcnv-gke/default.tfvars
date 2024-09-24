# GCP Settings
sa_creds           = "~/.gcp/astracontroltoolkitdev-terraform-sa-f8e9.json"
gcp_sa             = "terraform-sa@astracontroltoolkitdev.iam.gserviceaccount.com"
gcp_project        = "astracontroltoolkitdev"
gcp_project_number = "239048101169"
gcp_region         = "us-west4"
gcp_zones          = ["us-west4-b", "us-west4-c"]
creator_label      = "mhaigh"

# VPC Settings
gke_subnetwork_cidr   = "10.10.0.0/23"
gke_ip_range_control  = "172.16.0.0/28"
gke_ip_range_services = "172.17.0.0/16"
gke_ip_range_pods     = "172.18.0.0/16"

# GKE Cluster Settings
gke_kubernetes_version = "1.29.8-gke.1031000"
gke_private_cluster    = true
gke_trident_version    = "24.06.1"

# Node Pool Settings
gke_machine_type       = "e2-medium"
gke_image_type         = "COS_CONTAINERD"
gke_initial_node_count = 1 # per-zone
gke_min_node_count     = 1 # per-zone
gke_max_node_count     = 3 # per-zone

# GCNV Settings
gcnv_service_level = "standard"
gcnv_pool_capacity = "4096"

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

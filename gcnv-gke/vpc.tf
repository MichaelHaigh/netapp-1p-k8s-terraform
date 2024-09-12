# VPC Config
resource "google_compute_network" "gke_network" {
  name                    = "gke-${terraform.workspace}-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "gke-${terraform.workspace}-subnetwork"
  ip_cidr_range = var.gke_subnetwork_cidr
  network       = google_compute_network.gke_network.name
  secondary_ip_range {
    range_name    = "gke-${terraform.workspace}-subnetwork-pods"
    ip_cidr_range = var.gke_ip_range_pods
  }
  secondary_ip_range {
    range_name    = "gke-${terraform.workspace}-subnetwork-services"
    ip_cidr_range = var.gke_ip_range_services
  }
}

resource "google_compute_firewall" "gke_firewall" {
  name          = "gke-${terraform.workspace}-firewall"
  network       = google_compute_network.gke_network.name
  source_ranges = var.gke_private_cluster ? var.authorized_networks[*].cidr_block : ["0.0.0.0/0"]
  source_tags   = var.gke_private_cluster ? ["gke-${terraform.workspace}-cluster"] : []
  allow {
    protocol = "all"
  }
}

resource "google_compute_router" "gke_router" {
  name    = "gke-${terraform.workspace}-router"
  region  = var.gcp_region
  network = google_compute_network.gke_network.id
}

resource "google_compute_router_nat" "gke_nat" {
  name                               = "gke-${terraform.workspace}-router-nat"
  router                             = google_compute_router.gke_router.name
  region                             = google_compute_router.gke_router.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

resource "google_compute_global_address" "netapp_ip_range" {
  name          = "netapp-addresses-gke-${terraform.workspace}-network"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.gke_network.id
  depends_on = [
    google_compute_firewall.gke_firewall
  ]
}

resource "google_service_networking_connection" "netapp_connection" {
  network                 = google_compute_network.gke_network.id
  service                 = "netapp.servicenetworking.goog"
  reserved_peering_ranges = [google_compute_global_address.netapp_ip_range.name]
  depends_on = [
    google_compute_global_address.netapp_ip_range
  ]
  deletion_policy = "ABANDON"
}

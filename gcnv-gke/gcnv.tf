# GCNV Config
resource "google_netapp_storage_pool" "gcnv_pool" {
  provider      = google-beta
  name          = "gke-${terraform.workspace}-${var.gcnv_service_level}-pool"
  location      = var.gcp_region
  zone          = var.gcnv_service_level == "flex" ? var.gcp_zones[0] : null
  replica_zone  = var.gcnv_service_level == "flex" ? var.gcp_zones[1] : null
  service_level = upper(var.gcnv_service_level)
  capacity_gib  = var.gcnv_pool_capacity
  network       = google_compute_network.gke_network.id

  labels = {
      creator = "mhaigh"
  }

  depends_on = [
    google_service_networking_connection.netapp_connection
  ]
}

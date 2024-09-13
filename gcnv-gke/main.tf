terraform {
  required_version = ">= 0.12"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "~> 6.2.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "~> 6.2.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.32.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.6.3"
    }
  }
}

# Kubernetes provider for GKE Config
provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# Google provider
provider "google" {
  credentials = file(var.sa_creds)
  project     = var.gcp_project
  region      = var.gcp_region
}

# Google-beta provider for GCNV
provider "google-beta" {
  credentials = file(var.sa_creds)
  project     = var.gcp_project
  region      = var.gcp_region
}

output "kubernetes_endpoint" {
  sensitive = true
  value     = module.gke.endpoint
}

output "client_token" {
  sensitive = true
  value     = base64encode(data.google_client_config.default.access_token)
}

output "cloud_kubeconfig_cmd" {
  description = "The gcloud command to run to load kubeconfig credentials"
  value       = "gcloud container clusters get-credentials ${module.gke.name} --region ${var.gcp_zones[0]}"
}

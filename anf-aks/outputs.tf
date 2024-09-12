output "kubeconfig" {
  value     = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
  sensitive = true
}
output "az_kubeconfig_cmd" {
  value = "az aks get-credentials --resource-group aks-${terraform.workspace}-rg --name aks-${terraform.workspace}-cluster"
}

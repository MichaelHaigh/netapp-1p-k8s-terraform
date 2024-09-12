resource "azurerm_netapp_account" "aks_netapp_account" {
  name                = "aks-${terraform.workspace}-netappaccount"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name

  tags = {
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_netapp_pool" "aks_anf_pool" {
  name                = "aks-${terraform.workspace}-netapppool"
  account_name        = azurerm_netapp_account.aks_netapp_account.name
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
  service_level       = var.anf_service_level
  size_in_tb          = var.anf_pool_size

  tags = {
    environment = "${terraform.workspace}"
  }
}

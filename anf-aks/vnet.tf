resource "azurerm_virtual_network" "aks_vnet" {
  name                = "aks-${terraform.workspace}-vnet"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
  address_space       = [var.aks_vnet_cidr]

  tags = {
    environment = "${terraform.workspace}"
  }
}

resource "azurerm_subnet" "aks_anf_subnet" {
  name                 = "aks-${terraform.workspace}-anfsubnet"
  resource_group_name  = azurerm_resource_group.aks_resource_group.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.aks_anf_cidr]

  delegation {
    name = "netapp"

    service_delegation {
      name = "Microsoft.Netapp/volumes"
      actions = ["Microsoft.Network/networkinterfaces/*",
      "Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "aks_node_subnet" {
  name                 = "aks-${terraform.workspace}-nodesubnet"
  resource_group_name  = azurerm_resource_group.aks_resource_group.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = [var.aks_nodepool_cidr]
}

resource "azurerm_network_security_group" "aks_nsg" {
  name                = "aks-${terraform.workspace}-nsg"
  location            = azurerm_resource_group.aks_resource_group.location
  resource_group_name = azurerm_resource_group.aks_resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "aks_vnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.aks_node_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

resource "azurerm_network_security_rule" "allow_netapp_home_ips" {
  name                        = "aks-${terraform.workspace}-allowNetappHomeIps"
  resource_group_name         = azurerm_resource_group.aks_resource_group.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  description                 = "Allow NetApp and user home IPs addresses"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.authorized_networks[*].cidr_block
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "allow_azure_devops" {
  name                        = "aks-${terraform.workspace}-allowAzureDevOps"
  resource_group_name         = azurerm_resource_group.aks_resource_group.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  description                 = "Allow Azure DevOps Cluster Access"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "AzureDevOps"
  destination_address_prefix  = "*"
}

resource "azurerm_network_security_rule" "allow_all_443" {
  name                        = "aks-${terraform.workspace}-allowAll-443"
  resource_group_name         = azurerm_resource_group.aks_resource_group.name
  network_security_group_name = azurerm_network_security_group.aks_nsg.name
  description                 = "Allow Everything 443 Cluster Access"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefixes     = var.authorized_networks[*].cidr_block
  destination_address_prefix  = "*"
}

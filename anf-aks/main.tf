terraform {
  required_version = ">= 0.12"
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.53.1"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 4.1.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = jsondecode(file(var.sp_creds)).subscriptionId
  client_id       = jsondecode(file(var.sp_creds)).appId
  client_secret   = jsondecode(file(var.sp_creds)).password
  tenant_id       = jsondecode(file(var.sp_creds)).tenant
}

resource "azurerm_resource_group" "aks_resource_group" {
  name     = "aks-${terraform.workspace}-rg"
  location = var.azr_region

  tags = {
    environment = "${terraform.workspace}"
    creator     = "${var.creator_tag}"
  }
}

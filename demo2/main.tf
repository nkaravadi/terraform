terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
}
provider "azurerm" {
  features {}


}

resource "azurerm_resource_group" "rg" {
  name     = "demo"
  location = "eastus"
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "demo"

  default_node_pool {
    name       = "default"
    node_count = "2"
    vm_size    = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }
}
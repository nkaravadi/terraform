############### Providers ##################

terraform {
  required_version = ">=1.0"

  required_providers {

    azapi = {
      source  = "azure/azapi"
      version = "~>1.5"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }

  }

}

## Setup azurerm

provider "azurerm" {
  features {}
}


#############  Variables   #############

variable "resource_group_location" {
  type        = string
  default     = "eastus"
  description = "Location of the resource group."
}

variable "resource_group_name" {
  type        = string
  default     = "tf-demo-rg"
  description = "Name of the resource group with k8s."
}

variable "cluster_name" {
  type        = string
  default     = "tf-demo-cluster"
  description = "The k8s cluster name."
}

variable "dns_prefix" {
  type        = string
  default     = "tf-demo"
  description = "The k8s cluster's dns prefix."
}

variable "node_count" {
  type        = number
  description = "The initial quantity of nodes for the node pool."
  default     = 2
}

variable "username" {
  type        = string
  description = "The admin username for the new cluster."
  default     = "azureadmin"
}

############# Create resource group #############

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.resource_group_name
}

############# SSH Key ##################

resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = "tf-demo-sshk"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
}

output "key_data" {
  value = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
}

############# Create Kubernetes cluster #############

resource "azurerm_kubernetes_cluster" "k8s" {

  location            = azurerm_resource_group.rg.location
  name                = var.cluster_name
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name       = "agentpool"
    vm_size    = "Standard_D2s_v3"
    node_count = var.node_count
  }

  linux_profile {
    admin_username = var.username

    ssh_key {
      key_data = jsondecode(azapi_resource_action.ssh_public_key_gen.output).publicKey
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}


##### Outputs we need #######

output "kube_config" {
  value     = azurerm_kubernetes_cluster.k8s.kube_config_raw
  sensitive = true
}
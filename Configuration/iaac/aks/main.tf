resource "azurerm_resource_group" "rg" {
  name     = join("_", [var.resource_group_name, var.env])
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = join("-", [var.cluster_name, var.env])
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = join("-", [var.cluster_name, var.env])

  # azure will assign the id automatically
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name                 = "system"
    node_count           = var.system_node_count
    vm_size              = "Standard_DS2_v2"
	  type                 = "VirtualMachineScaleSets"
	  min_count            = 2
	  max_count            = 5
	  enable_auto_scaling  = true
  }

  role_based_access_control {
    enabled = true
  }

  network_profile {
    load_balancer_sku = "Standard"
    network_plugin    = "kubenet" # CNI
  }
}

data "azurerm_container_registry" "acr" {
  name                = "_#{acr_name}#_"
  resource_group_name = "_#{acr_rg}#_"
}

resource "azurerm_role_assignment" "role_acrpull" {
  scope                = data.azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

terraform {
  backend "azurerm" {}
}
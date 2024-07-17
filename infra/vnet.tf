# Based on https://github.com/jpflueger/spin-k8s-bench/blob/main/infra/azure/vnet.tf

resource "azurerm_virtual_network" "main" {
  name = "vnet-${local.base_name}"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = local.tags
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "aks" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "user_nodepools" {
  count = length(var.user_nodepools)

  name                 = var.user_nodepools[count.index].name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.main.name

  address_prefixes = ["10.10.${count.index + 2}.0/24"]
}

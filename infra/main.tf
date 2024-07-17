# Based on https://github.com/jpflueger/spin-k8s-bench/blob/main/infra/azure/main.tf

resource "random_id" "cluster_name" {
  byte_length = 4
}

# Local for tag to attach to all items
locals {
  base_name = "${var.prefix}${random_id.cluster_name.hex}"
  tags = merge(
    {
      "ClusterName" = local.base_name
    },
    var.tags
  )
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "sa" {
  name                     = "sa${local.base_name}" # max length of 24  
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_storage_container" "demo" {
  name                  = "container-${local.base_name}"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "demo" {
  name                 = "queue-${local.base_name}"
  storage_account_name = azurerm_storage_account.sa.name
}


resource "azurerm_kubernetes_cluster" "aks" {
  name = "aks-${local.base_name}"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  kubernetes_version = var.kubernetes_version
  sku_tier           = var.sku_tier

  azure_policy_enabled             = false
  http_application_routing_enabled = false

  dns_prefix = local.base_name

  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    load_balancer_sku = "standard"
  }

  default_node_pool {
    name                         = var.system_nodepool.name
    node_count                   = var.system_nodepool.min
    vm_size                      = var.system_nodepool.size
    enable_auto_scaling          = var.system_nodepool.min != var.system_nodepool.max
    min_count                    = var.system_nodepool.min != var.system_nodepool.max ? var.system_nodepool.min : null
    max_count                    = var.system_nodepool.min != var.system_nodepool.max ? var.system_nodepool.max : null
    only_critical_addons_enabled = true
    vnet_subnet_id               = azurerm_subnet.aks.id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_kubernetes_cluster_node_pool" "user_nodepools" {
  count = length(var.user_nodepools)

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  name                  = var.user_nodepools[count.index].name
  vm_size               = var.user_nodepools[count.index].name == "apps" && var.apps_nodepool_sku != "" ? var.apps_nodepool_sku : var.user_nodepools[count.index].size

  mode    = "User" # Indicating that these nodepools are used for workloads created by the user (developer)
  os_type = "Linux"
  os_sku  = "Ubuntu"

  node_count  = var.user_nodepools[count.index].node_count
  node_labels = var.user_nodepools[count.index].labels
  node_taints = var.user_nodepools[count.index].taints

  max_pods = var.user_nodepools[count.index].max_pods

  vnet_subnet_id = azurerm_subnet.user_nodepools[count.index].id

  tags = local.tags
}

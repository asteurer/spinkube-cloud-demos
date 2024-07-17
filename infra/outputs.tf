output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "aks_cluster" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "storage_account_primary_access_key" {
  value     = azurerm_storage_account.sa.primary_access_key
  sensitive = true
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "container_name" {
  value = azurerm_storage_container.demo.name
}

output "queue_name" {
  value = azurerm_storage_queue.demo.name
}

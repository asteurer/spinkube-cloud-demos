output "storage_account_primary_access_key" {
  value = azurerm_storage_account.demo.primary_access_key
  sensitive = true
}

output "storage_account_name" {
    value = azurerm_storage_account.demo.name
}

output "container_name" {
  value = azurerm_storage_container.demo.name
}

output "queue_name" {
  value = azurerm_storage_queue.demo.name
}
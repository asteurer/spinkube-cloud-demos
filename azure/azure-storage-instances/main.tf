terraform {
  required_version = ">=1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.99.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_id" "demo" {
    byte_length = 4
}

locals {
    base_name = "${var.prefix}${random_id.demo.hex }"
    tags =var.tags
}

resource "azurerm_resource_group" "demo" {
  name     = "rg-${local.base_name}"
  location = var.location
}

resource "azurerm_storage_account" "demo" {
  name                     = "${local.base_name}"
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_resource_group.demo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "demo" {
  name                  = "container-${local.base_name}"
  storage_account_name  = azurerm_storage_account.demo.name
  container_access_type = "private"
}

resource "azurerm_storage_queue" "demo" {
  name = "queue-${local.base_name}"
  storage_account_name = azurerm_storage_account.demo.name
}
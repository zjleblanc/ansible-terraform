resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_storage_account" "tfstate" {
  name                     = var.az_storage_account
  resource_group_name      = var.az_resource_group
  location                 = var.az_resource_group_loc
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_nested_items_to_be_public = false

  tags = {
    repo = "ansible-terraform"
    owner = "zleblanc"
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.az_storage_account_container
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
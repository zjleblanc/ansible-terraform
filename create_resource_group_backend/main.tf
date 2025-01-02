resource "azurerm_resource_group" "example" {
  name     = var.az_resource_group
  location = var.az_resource_group_loc
}
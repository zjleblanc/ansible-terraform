# variable "az_client_id" {}
# variable "az_client_secret" {}
# variable "az_tenant" {}
# variable "az_subscription" {}

variable "az_resource_group" { default = "openenv-jmdmt" }
variable "az_resource_group_loc" { default = "eastus" }
variable "az_storage_account" { default = "zjltfstatemgmtsa" }
variable "az_storage_account_container" { default = "tfstate" }
variable "az_region" { default = "southcentralus"}
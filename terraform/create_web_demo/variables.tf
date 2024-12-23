variable "az_client_id" {}
variable "az_client_secret" {}
variable "az_tenant" {}
variable "az_subscription" {}
variable "az_storage_account_key" {}

# Generic Az vars
variable "az_resource_group" { default = "tf-web-demo-rg" }
variable "az_region" { default = "southcentralus" }
# Backend storage vars
variable "backend_resource_group" { default = "tf-state-mgmt" }
variable "backend_storage_account" { default = "zjltfstatemgmtsa" }
# Web demo vars
variable "web_nic_name" { default = "web-demo-nic" }
variable "web_vm_name" { default = "web-demo-vm" }
variable "web_vnet_name" { default = "web-demo-vnet" }
variable "web_subnet_name" { default = "web-demo-subnet" }
variable "web_demo_admin_username" { default = "zach" }
variable "web_demo_ssh_pubkey_name" { default = "web-demo-ssh-pubkey" }
variable "web_demo_ssh_pubkey_local_path" { default = "~/.ssh/id_rsa.pub" }
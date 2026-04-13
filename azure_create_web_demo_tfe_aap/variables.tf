# Azure provider authentication
variable "az_client_id" { type = string }
variable "az_client_secret" { type = string }
variable "az_tenant_id" { type = string }
variable "az_subscription_id" { type = string }

# Generic Az vars
variable "az_resource_group" { default = "aap-tfe-web-demo-rg" }
variable "az_region" { default = "southcentralus" }
variable "web_tags_base" {
  default = {
    owner       = "zleblanc"
    demo        = "web"
    deployment  = "terraform"
    config      = "ansible"
    cost-center = "ZJL"
  }
}
# Web demo vars
variable "web_nic_name" { default = "web-demo-nic" }
variable "web_vm_name" { default = "web-demo-vm" }
variable "web_vm_size" { default = "Standard_DS1_v2" }
variable "web_vnet_name" { default = "web-demo-vnet" }
variable "web_subnet_name" { default = "web-demo-subnet" }
variable "web_nsg_name" { default = "web-demo-nsg" }
variable "web_demo_admin_username" { default = "zach" }
variable "web_demo_ssh_pubkey_name" { default = "web-demo-ssh-pubkey" }
variable "web_demo_ssh_pubkey" {}
# Output metadata
variable "aap_job_url" {
  type    = string
  default = "N/A"
}
variable "aap_workflow_url" {
  type    = string
  default = "N/A"
}
variable "sc_task" {
  type    = string
  default = "N/A"
}
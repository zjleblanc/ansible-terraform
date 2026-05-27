# Azure provider authentication
variable "az_client_id" { type = string }
variable "az_client_secret" { type = string }
variable "az_tenant_id" { type = string }
variable "az_subscription_id" { type = string }

# Generic Az vars
variable "az_resource_group" { default = "aap-tf-web-demo-rg" }
variable "az_region" { default = "eastus" }
variable "web_tags_base" {
  default = {
    owner       = "zleblanc"
    demo        = "web"
    deployment  = "terraform"
    config      = "ansible"
    environment = "sandbox"
    cost-center = "ZJL"
  }
}
# Web demo vars
variable "web_nic_name" { default = "aap-tf-demo-nic" }
variable "web_vm_name" { default = "aap-tf-demo-vm" }
variable "web_vm_size" { default = "Standard_DS1_v2" }
variable "web_vnet_name" { default = "aap-tf-demo-vnet" }
variable "web_subnet_name" { default = "aap-tf-demo-subnet" }
variable "web_nsg_name" { default = "aap-tf-demo-nsg" }
variable "aap_tf_demo_admin_username" { default = "zach" }
variable "aap_tf_demo_ssh_pubkey_name" { default = "aap-tf-demo-ssh-pubkey" }
variable "aap_tf_demo_ssh_pubkey" {}

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
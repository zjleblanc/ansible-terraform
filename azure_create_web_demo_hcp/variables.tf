# Generic Az vars
variable "az_resource_group" { default = "tf-web-demo-rg" }
variable "az_region" { default = "southcentralus" }
variable "web_tags_base" {
  default = {
    owner = "zleblanc"
    demo = "web"
    deployment = "terraform"
    config = "ansible"
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
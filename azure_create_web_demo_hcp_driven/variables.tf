# -----------------------------------------------------------------------------
# Azure provider authentication
# -----------------------------------------------------------------------------
variable "az_client_id" { type = string }
variable "az_client_secret" { type = string }
variable "az_tenant_id" { type = string }
variable "az_subscription_id" { type = string }

# -----------------------------------------------------------------------------
# Generic Azure vars
# -----------------------------------------------------------------------------
variable "az_resource_group" { default = "tf-hcp-driven-web-demo-rg" }
variable "az_region" { default = "southcentralus" }
variable "web_tags_base" {
  default = {
    owner      = "zleblanc"
    demo       = "web"
    deployment = "terraform"
    config     = "ansible"
  }
}

# -----------------------------------------------------------------------------
# Web demo Azure vars
# -----------------------------------------------------------------------------
variable "web_nic_name" { default = "web-demo-nic" }
variable "web_vm_name" { default = "web-demo-vm" }
variable "web_vm_size" { default = "Standard_DS1_v2" }
variable "web_vnet_name" { default = "web-demo-vnet" }
variable "web_subnet_name" { default = "web-demo-subnet" }
variable "web_nsg_name" { default = "web-demo-nsg" }
variable "web_demo_admin_username" { default = "zach" }
variable "web_demo_ssh_pubkey_name" { default = "web-demo-ssh-pubkey" }
variable "web_demo_ssh_pubkey" {}

# -----------------------------------------------------------------------------
# Ansible Automation Platform (certified AAP provider)
# -----------------------------------------------------------------------------
variable "aap_host" {
  type        = string
  description = "https://aap.example.com"
}
variable "aap_token" {
  type        = string
  description = "AAP token for API access"
}

variable "aap_organization_name" {
  type        = string
  description = "AAP organization name for Job Template and Inventory"
  default     = "Autodotes"
}
variable "aap_inventory_name" {
  type        = string
  description = "Name of the AAP inventory to place the web demo hosts"
}
variable "aap_job_template_name" {
  type        = string
  description = "Name of the AAP Job Template that runs the downstream playbook"
  default     = "Terraform // HCP-Driven // Web Demo Configure"
}
variable "aap_insecure_skip_verify" {
  type        = bool
  default     = false
  description = "Skip TLS verification for AAP API"
}
variable "aap_timeout" {
  type        = number
  default     = 5
  description = "Timeout in seconds for AAP API requests (0 = no timeout)"
}

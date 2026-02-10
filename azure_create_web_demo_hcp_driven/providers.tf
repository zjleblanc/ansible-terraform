# Azure + Ansible Automation Platform (certified AAP provider)
terraform {
  cloud {
    # sourced from custom Credential Type for flexibility
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
    aap = {
      source  = "ansible/aap"
      version = "~> 0.4"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  client_id       = var.az_client_id
  client_secret   = var.az_client_secret
  tenant_id       = var.az_tenant_id
  subscription_id = var.az_subscription_id
}

# Configure the Red Hat Ansible Automation Platform provider
provider "aap" {
  host     = var.aap_host
  token = var.aap_token

  insecure_skip_verify = var.aap_insecure_skip_verify
  timeout              = var.aap_timeout
}

# Configure the Azure provider
terraform {
  cloud {
    # sourced from custom Credential Type for flexibility
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
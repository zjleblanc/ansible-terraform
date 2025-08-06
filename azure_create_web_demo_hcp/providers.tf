# Configure the Azure provider
terraform {
  cloud {
    # sourced from custom Credential Type for flexibility
    workspaces {
      name = "azure-web-demo-dev"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.1.0"
    }
  }

  backend "azurerm" {}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
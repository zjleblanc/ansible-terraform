# Configure the Azure provider
terraform {
  cloud {
    # organization = "zleblanc" # Source from Credential for flexibility
    # hostname = "app.terraform.io" # Source from Credential for flexibility

    workspaces {
      name = "ansible-tf-demos"
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
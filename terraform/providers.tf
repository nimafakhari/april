terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Remote state in Azure Storage. Values supplied via -backend-config in CI.
  backend "azurerm" {}
}

provider "azurerm" {
  features {}
}

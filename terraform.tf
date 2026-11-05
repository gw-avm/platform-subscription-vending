terraform {
  required_version = "~> 1.14"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.12"
    }
  }

  # Settings come from the workflow: one state file per landing zone
  # (key = <landing zone>.tfstate), Entra ID auth, no storage keys.
  backend "azurerm" {}
}

provider "azapi" {}

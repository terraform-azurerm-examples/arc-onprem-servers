terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.33.0"
    }

    http = {
      source  = "hashicorp/http"
      version = ">= 3.2.1"
    }
  }
}

provider "azurerm" {
  features {}

  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id
}

provider "azurerm" {
  features {}
  alias           = "hackteam"
  tenant_id       = var.hackteam_tenant_id != null ? var.hackteam_tenant_id : var.tenant_id
  subscription_id = var.hackteam_subscription_id != null ? var.hackteam_subscription_id : var.subscription_id
}

provider "azuread" {}

provider "azuread" {
  alias     = "hackteam"
  tenant_id = var.hackteam_tenant_id != null ? var.hackteam_tenant_id : var.tenant_id
}

provider "random" {}
provider "local" {}
provider "cloudinit" {}
provider "http" {}

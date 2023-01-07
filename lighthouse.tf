// Azure Lighthouse

data "azurerm_role_definition" "contributor" {
  role_definition_id = "b24988ac-6180-42a0-ab88-20f7382dd24c"
}

data "azurerm_role_definition" "delete_lighthouse_assignment" {
  role_definition_id = "91c1777a-f3dc-4fae-b103-61d183457e46"
}

locals {
  lighthouse = toset(var.lighthouse != null ? [var.lighthouse.name] : [])
}

resource "azurerm_lighthouse_definition" "lighthouse" {
  for_each = local.lighthouse

  name               = var.lighthouse.name
  description        = var.lighthouse.description
  managing_tenant_id = var.lighthouse.managing_tenant_id
  scope              = "/subscriptions/${var.subscription_id}"

  authorization {
    principal_id           = var.lighthouse.principal_id
    role_definition_id     = data.azurerm_role_definition.contributor.role_definition_id
    principal_display_name = var.lighthouse.principal_display_name
  }

  authorization {
    principal_id           = var.lighthouse.principal_id
    role_definition_id     = data.azurerm_role_definition.delete_lighthouse_assignment.role_definition_id
    principal_display_name = var.lighthouse.principal_display_name
  }
}

resource "azurerm_lighthouse_assignment" "lighthouse" {
  for_each                 = local.lighthouse
  scope                    = "/subscriptions/${var.subscription_id}"
  lighthouse_definition_id = azurerm_lighthouse_definition.lighthouse[each.value].id
}

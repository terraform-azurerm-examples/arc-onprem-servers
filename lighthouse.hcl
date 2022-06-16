data "azurerm_role_definition" "contributor" {
  role_definition_id = "b24988ac-6180-42a0-ab88-20f7382dd24c"
}

data "azurerm_role_definition" "delete_lighthouse_assignment" {
  role_definition_id = "91c1777a-f3dc-4fae-b103-61d183457e46"
}

resource "azurerm_lighthouse_definition" "lighthouse" {
  name               = "name"
  description        = "description"
  managing_tenant_id = "managing_tenant_id"
  scope              = "/subscriptions/${var.subscription_id}"

  authorization {
    principal_id           = "principal_id" # az ad signed-in-user show --query id --output tsv
    role_definition_id     = data.azurerm_role_definition.contributor.role_definition_id
    principal_display_name = "cosmetic_display_name - Contributor"
  }

  authorization {
    principal_id           = "principal_id" # az ad signed-in-user show --query id --output tsv
    role_definition_id     = data.azurerm_role_definition.delete_lighthouse_assignment.role_definition_id
    principal_display_name = "cosmetic_display_name - Delete Lighthouse Assignments"
  }
}

resource "azurerm_lighthouse_assignment" "lighthouse" {
  scope                    = "/subscriptions/${var.subscription_id}"
  lighthouse_definition_id = azurerm_lighthouse_definition.lighthouse.id
}
data "azuread_client_config" "current" {
  provider = azuread.hackteam
  for_each = local.hackteam
}

locals {
  hackteam                 = toset(var.hackteam != null ? [var.hackteam] : [])
  hackteam_tenant_id       = var.hackteam_tenant_id != null ? var.hackteam_tenant_id : var.tenant_id
  hackteam_subscription_id = var.hackteam_subscription_id != null ? var.hackteam_subscription_id : var.subscription_id
}

resource "azuread_group" "hackteam" {
  provider = azuread.hackteam
  for_each = local.hackteam

  lifecycle {
    ignore_changes = [
      owners,
      members,
    ]
  }

  display_name     = "Hack Team"
  mail_enabled     = false
  security_enabled = true

  owners = [
    data.azuread_client_config.current[var.hackteam].object_id
  ]

  members = [
    data.azuread_client_config.current[var.hackteam].object_id
  ]
}

resource "azurerm_resource_group" "hackteam" {
  provider = azurerm.hackteam
  for_each = local.hackteam

  name     = var.hackteam_resource_group_name
  location = var.location

  lifecycle {
    ignore_changes = [tags, ]
  }
}

resource "azurerm_role_assignment" "hackteam" {
  scope                = "/subscriptions/${local.hackteam_subscription_id}"
  role_definition_name = "Owner"
  principal_id         = azuread_group.hackteam[var.hackteam].object_id
}

resource "azurerm_ssh_public_key" "hackteam" {
  provider = azurerm.hackteam
  for_each = local.hackteam

  name                = "${var.hackteam}-onprem-ssh-public-key"
  resource_group_name = upper(azurerm_resource_group.hackteam[var.hackteam].name)
  location            = var.linux_location
  public_key          = file(var.admin_ssh_key_file)
}

resource "azurerm_key_vault" "hackteam" {
  provider = azurerm.hackteam
  for_each = local.hackteam

  name                       = "arc-hack-${var.hackteam}"
  tenant_id                  = local.hackteam_tenant_id
  resource_group_name        = azurerm_resource_group.hackteam[var.hackteam].name
  location                   = var.linux_location
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = local.source_address_prefixes
  }

  access_policy {
    tenant_id = local.hackteam_tenant_id
    object_id = data.azuread_client_config.current[var.hackteam].object_id

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }

  access_policy {
    tenant_id = local.hackteam_tenant_id
    object_id = resource.azuread_group.hackteam[var.hackteam].object_id

    secret_permissions = [
      "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
    ]
  }
}

resource "azurerm_key_vault_secret" "hackteam" {
  provider = azurerm.hackteam
  for_each = local.hackteam

  name         = "${var.hackteam}-onprem-ssh-private-key"
  value        = base64encode(file(trimsuffix(var.admin_ssh_key_file, ".pub")))
  key_vault_id = azurerm_key_vault.hackteam[var.hackteam].id
}

resource "local_file" "wiki" {
  for_each        = local.hackteam
  filename        = "${path.module}/wiki.md"
  file_permission = "0664"
  content         = <<WIKI
# Azure Arc for Management & Governance partner hack

## Admin Username

`onpremadmin`

## Windows Admin Password

`${local.windows_admin_password}`

## Windows Servers

```text
%{for name in local.windows_vm_names~}
${module.windows_vms[name].fqdn}
%{endfor~}
```

## Linux Servers

```text
%{for name in local.linux_vm_names~}
${module.linux_vms[name].ssh_command} -i ~/.ssh/${var.hackteam}
%{endfor~}
```

## SSH Keys (Bash)

```bash
[[ ! -s ~/.ssh/${var.hackteam} ]] && ssh-keygen -f ~/.ssh/${var.hackteam} -N ''
az sshkey show --name ${var.hackteam}-onprem-ssh-public-key \
  --subscription ${local.hackteam_subscription_id} \
  --resource-group ${azurerm_resource_group.hackteam[var.hackteam].name} \
  --query publicKey --output tsv > ~/.ssh/${var.hackteam}.pub
vault=$(az keyvault list --resource-group ${azurerm_resource_group.hackteam[var.hackteam].name} --query [0].name --output tsv)
az keyvault secret show --name ${var.hackteam}-onprem-ssh-private-key \
  --vault-name ${azurerm_key_vault.hackteam[var.hackteam].name} \
  --query value --output tsv | base64 -d > ~/.ssh/${var.hackteam}
```

## SSH Keys (PowerShell)

```powershell
if (!(test-path -path ~/.ssh)) {new-item -path ~/.ssh -itemtype directory}
ssh-keygen -f ".ssh\${var.hackteam}" -N " "
$PSDefaultParameterValues['Out-File:Encoding'] = 'UTF8'
az sshkey show --name ${var.hackteam}-onprem-ssh-public-key `
  --subscription ${local.hackteam_subscription_id} `
  --resource-group ${azurerm_resource_group.hackteam[var.hackteam].name} `
  --query publicKey --output tsv > ~/.ssh/${var.hackteam}.pub
$vault = $(az keyvault list --resource-group ${azurerm_resource_group.hackteam[var.hackteam].name} --query [0].name --output tsv)
$key = $(az keyvault secret show --name ${var.hackteam}-onprem-ssh-private-key `
  --vault-name ${azurerm_key_vault.hackteam[var.hackteam].name} `
  --query value --output tsv)
[Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($key)) > ~/.ssh/${var.hackteam}
```
WIKI
}

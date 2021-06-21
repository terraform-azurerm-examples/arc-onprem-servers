terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.51.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}
provider "random" {}
provider "template" {}

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

locals {
  name = try(length(var.resource_prefix), 0) > 0 ? "${var.resource_prefix}-arc-onprem-servers" : "arc-onprem-servers"

  uniq = substr(sha1(azurerm_resource_group.arc.id), 0, 8)

  linux_vm_names = length(var.linux_vm_names) > 0 ? var.linux_vm_names : [for n in range(var.linux_count) :
    format("%s-%02d", var.linux_prefix, n + 1)
  ]

  windows_vm_names = length(var.windows_vm_names) > 0 ? var.windows_vm_names : [for n in range(var.windows_count) :
    format("%s-%02d", var.windows_prefix, n + 1)
  ]

  windows_admin_password = format("%s!", title(random_pet.arc.id))
}

// Resource groups

resource "azurerm_resource_group" "arc" {
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    ignore_changes = [tags, ]
  }
}

resource "azurerm_ssh_public_key" "arc" {
  name                = "${local.name}-ssh-public-key"
  resource_group_name = upper(azurerm_resource_group.arc.name)
  location            = azurerm_resource_group.arc.location
  public_key          = file(var.admin_ssh_key_file)
}

resource "random_pet" "arc" {
  length = 2
  keepers = {
    resource_group_id = azurerm_resource_group.arc.id
  }
}

// Networking

resource "azurerm_application_security_group" "linux" {
  name                = "${local.name}-linux-asg"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
}

resource "azurerm_application_security_group" "windows" {
  name                = "${local.name}-windows-asg"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
}

resource "azurerm_network_security_group" "arc" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
}

resource "azurerm_network_security_rule" "ssh" {
  resource_group_name         = azurerm_resource_group.arc.name
  network_security_group_name = azurerm_network_security_group.arc.name

  name                                       = "SSH"
  priority                                   = 1000
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
  destination_port_range                     = "22"
}

resource "azurerm_network_security_rule" "rdp" {
  resource_group_name         = azurerm_resource_group.arc.name
  network_security_group_name = azurerm_network_security_group.arc.name

  name                                       = "RDP"
  priority                                   = 1001
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
  destination_port_range                     = "3389"
}

resource "azurerm_network_security_rule" "winrm" {
  resource_group_name         = azurerm_resource_group.arc.name
  network_security_group_name = azurerm_network_security_group.arc.name

  name                                       = "WinRm"
  priority                                   = 1002
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
  destination_port_ranges                    = ["5985", "5986"]
}

resource "azurerm_network_security_rule" "nginx" {
  resource_group_name         = azurerm_resource_group.arc.name
  network_security_group_name = azurerm_network_security_group.arc.name

  name                                       = "NginX"
  priority                                   = 1003
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
  destination_port_ranges                    = ["80", "443"]
}

resource "azurerm_virtual_network" "arc" {
  name                = "${local.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.arc.location
  resource_group_name = azurerm_resource_group.arc.name
}

resource "azurerm_subnet" "arc" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.arc.name
  virtual_network_name = azurerm_virtual_network.arc.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "arc" {
  subnet_id                 = azurerm_subnet.arc.id
  network_security_group_id = azurerm_network_security_group.arc.id
}

// Linux virtual machines

module "linux_vms" {
  source              = "../terraform-azurerm-arc-onprem-linux-vm"
  resource_group_name = azurerm_resource_group.arc.name
  location            = azurerm_resource_group.arc.location
  tags                = var.tags

  for_each = toset(local.linux_vm_names)

  name                 = each.value
  size                 = var.linux_size
  dns_label            = "arc-${local.uniq}-${each.value}"
  subnet_id            = azurerm_subnet.arc.id
  asg_id               = azurerm_application_security_group.linux.id
  admin_ssh_public_key = azurerm_ssh_public_key.arc.public_key

  azcmagent = var.azcmagent
  arc       = var.arc
}

module "windows_vms" {
  source              = "../terraform-azurerm-arc-onprem-windows-vm"
  resource_group_name = azurerm_resource_group.arc.name
  location            = azurerm_resource_group.arc.location
  tags                = var.tags

  for_each        = toset(local.windows_vm_names)
  resource_prefix = var.resource_prefix

  name           = each.value
  size           = var.windows_size
  dns_label      = "arc-${local.uniq}-${each.value}"
  subnet_id      = azurerm_subnet.arc.id
  asg_id         = azurerm_application_security_group.windows.id
  admin_password = local.windows_admin_password

  azcmagent = var.azcmagent
  arc       = var.arc
}

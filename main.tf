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
  name = try(length(var.resource_prefix), 0) > 0 ? "${var.resource_prefix}-onprem_servers" : "onprem_servers"

  uniq = substr(sha1(azurerm_resource_group.onprem.id), 0, 8)

  linux_vm_names = length(var.linux_vm_names) > 0 ? var.linux_vm_names : [for n in range(var.linux_count) :
    format("%s-%02d", var.linux_prefix, n + 1)
  ]

  windows_vm_names = length(var.windows_vm_names) > 0 ? var.windows_vm_names : [for n in range(var.windows_count) :
    format("%s-%02d", var.windows_prefix, n + 1)
  ]

  windows_admin_password = format("%s!", title(random_pet.onprem.id))

  # Set a boolean for the connect if the arc object has been set
  azcmagent_connect = var.arc == null ? false : true

  // And then force azcmagent_download to true
  azcmagent_download = local.azcmagent_connect ? true : var.azcmagent
}

// Resource groups

resource "azurerm_resource_group" "onprem" {
  name     = var.resource_group_name
  location = var.location

  lifecycle {
    ignore_changes = [tags, ]
  }
}

resource "azurerm_ssh_public_key" "onprem" {
  name                = "${local.name}-ssh-public-key"
  resource_group_name = upper(azurerm_resource_group.onprem.name)
  location            = azurerm_resource_group.onprem.location
  public_key          = file(var.admin_ssh_key_file)
}

resource "random_pet" "onprem" {
  length = 2
  keepers = {
    resource_group_id = azurerm_resource_group.onprem.id
  }
}

// Networking

resource "azurerm_application_security_group" "linux" {
  name                = "${local.name}-linux-asg"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_application_security_group" "windows" {
  name                = "${local.name}-windows-asg"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_network_security_group" "onprem" {
  name                = "${local.name}-nsg"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_network_security_rule" "ssh" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

  name                                       = "SSH"
  priority                                   = 1000
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "VirtualNetwork"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
  destination_port_range                     = "22"
}

resource "azurerm_network_security_rule" "rdp" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

  name                                       = "RDP"
  priority                                   = 1001
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "VirtualNetwork"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
  destination_port_range                     = "3389"
}

resource "azurerm_network_security_rule" "winrm" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

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

resource "azurerm_network_security_rule" "wac" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

  name                                       = "WindowsAdminCenter"
  priority                                   = 1003
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
  destination_port_ranges                    = ["6516"]
}

resource "azurerm_network_security_rule" "web" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

  name                                       = "web"
  priority                                   = 1004
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "*"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.linux.id, azurerm_application_security_group.windows.id]
  destination_port_ranges                    = ["80", "443"]
}

resource "azurerm_network_security_rule" "smb" {
  resource_group_name         = azurerm_resource_group.onprem.name
  network_security_group_name = azurerm_network_security_group.onprem.name

  name                                       = "SMB"
  priority                                   = 1005
  direction                                  = "Inbound"
  access                                     = "Allow"
  protocol                                   = "Tcp"
  source_address_prefix                      = "VirtualNetwork"
  source_port_range                          = "*"
  destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
  destination_port_ranges                    = ["445"]
}

resource "azurerm_virtual_network" "onprem" {
  name                = "${local.name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_subnet" "bastion" {
  for_each             = toset(var.bastion ? ["onprem"] : [])
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = ["10.0.0.0/27"]
}

resource "azurerm_subnet" "onprem" {
  name                 = "${local.name}-subnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet_network_security_group_association" "onprem" {
  subnet_id                 = azurerm_subnet.onprem.id
  network_security_group_id = azurerm_network_security_group.onprem.id
}

// Bastion

resource "azurerm_public_ip" "bastion" {
  for_each            = toset(var.bastion ? ["onprem"] : [])
  name                = "${local.name}-bastion-pip"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  for_each            = toset(var.bastion ? ["onprem"] : [])
  name                = "${local.name}-bastion"
  location            = azurerm_resource_group.onprem.location
  resource_group_name = azurerm_resource_group.onprem.name

  ip_configuration {
    name                 = "bastion-ipconfig"
    subnet_id            = azurerm_subnet.bastion["onprem"].id
    public_ip_address_id = azurerm_public_ip.bastion["onprem"].id
  }
}

// Linux virtual machines

module "linux_vms" {
  // source              = "../terraform-azurerm-arc-onprem-linux-vm"
  source              = "github.com/terraform-azurerm-modules/terraform-azurerm-arc-onprem-linux-vm?ref=v1.0"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  tags                = var.tags

  for_each = toset(local.linux_vm_names)

  name                 = each.value
  size                 = var.linux_size
  public_ip            = var.pip && !var.bastion ? true : false
  dns_label            = var.pip && !var.bastion ? "onprem-${local.uniq}-${each.value}" : null
  subnet_id            = azurerm_subnet.onprem.id
  asg_id               = azurerm_application_security_group.linux.id
  admin_username       = var.admin_username
  admin_ssh_public_key = azurerm_ssh_public_key.onprem.public_key

  azcmagent = local.azcmagent_download
  arc       = var.arc
}

module "windows_vms" {
  // source              = "../terraform-azurerm-arc-onprem-windows-vm"
  source              = "github.com/terraform-azurerm-modules/terraform-azurerm-arc-onprem-windows-vm?ref=v1.0"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = azurerm_resource_group.onprem.location
  tags                = var.tags

  for_each = toset(local.windows_vm_names)

  name           = each.value
  size           = var.windows_size
  public_ip      = var.pip && (each.value == local.windows_vm_names[0] || !var.bastion) ? true : false
  dns_label      = var.pip && (each.value == local.windows_vm_names[0] || !var.bastion) ? "onprem-${local.uniq}-${each.value}" : null
  subnet_id      = azurerm_subnet.onprem.id
  asg_id         = azurerm_application_security_group.windows.id
  admin_username = var.admin_username
  admin_password = local.windows_admin_password

  azcmagent = local.azcmagent_download
  arc       = var.arc
}

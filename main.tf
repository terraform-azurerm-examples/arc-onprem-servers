data "http" "source_address" {
  // url = "https://ipinfo.io/ip" // Blocked on corpnet!
  url = "https://myexternalip.com/raw"

  request_headers = {
    Accept = "application/json"
  }
}

locals {
  name = "onprem_servers"

  uniq = substr(sha1(azurerm_resource_group.onprem.id), 0, 8)

  linux_vm_names = length(var.linux_vm_names) > 0 ? var.linux_vm_names : [for n in range(var.linux_count) :
    format("%s-%02d", var.linux_prefix, n + 1)
  ]

  windows_vm_names = length(var.windows_vm_names) > 0 ? var.windows_vm_names : [for n in range(var.windows_count) :
    format("%s-%02d", var.windows_prefix, n + 1)
  ]

  windows_location = var.windows_location != null ? var.windows_location : var.location
  linux_location   = var.linux_location != null ? var.linux_location : var.location

  split_vnet = local.windows_location == local.linux_location ? false : true

  vnet = local.split_vnet ? {
    (local.windows_location) = {
      name          = format("%s-%s-vnet", local.name, local.windows_location)
      location      = local.windows_location
      address_space = "10.0.0.0/23"
      subnets = {
        bastion = "10.0.0.0/24"
        windows = "10.0.1.0/24"
      }
    }
    (local.linux_location) = {
      name          = format("%s-%s-vnet", local.name, local.linux_location)
      location      = local.linux_location
      address_space = "10.0.2.0/23"
      subnets = {
        linux = "10.0.2.0/24"
      }
    }
    } : {
    (local.windows_location) = {
      name          = format("%s-%s-vnet", local.name, local.windows_location)
      location      = local.windows_location
      address_space = "10.0.0.0/22"
      subnets = {
        bastion = "10.0.0.0/24"
        windows = "10.0.1.0/24"
        linux   = "10.0.2.0/24"
      }
    }


  }

  windows_admin_password = var.windows_admin_password == null ? format("%s!", title(random_pet.onprem.id)) : var.windows_admin_password

  azcmagent = var.azcmagent != null ? var.azcmagent : var.arc != null ? {
    windows = {
      install = true
      connect = true
    }
    linux = {
      install = true
      connect = true
    }
    } : {
    windows = {
      install = false
      connect = false
    }
    linux = {
      install = false
      connect = false
    }
  }

  # Use source_address_prefices if set, if not just use current public IP
  source_address_prefixes = setunion(var.source_address_prefixes, [data.http.source_address.response_body])

  # Set a boolean for the connect if the arc object has been set
  # azcmagent_connect = var.arc == null ? false : true

  // And then force azcmagent_download to true
  # azcmagent_download = local.azcmagent_connect ? true : var.azcmagent
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
  location            = local.linux_location
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
  name                = format("%s-%s-linux-asg", local.name, local.linux_location)
  location            = local.linux_location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_application_security_group" "windows" {
  name                = format("%s-%s-windows-asg", local.name, local.windows_location)
  location            = local.windows_location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_network_security_group" "linux" {
  name                = format("%s-%s-linux-nsg", local.name, local.linux_location)
  location            = local.linux_location
  resource_group_name = azurerm_resource_group.onprem.name

  security_rule {
    name                                       = "SSH"
    priority                                   = 1000
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefixes                    = local.source_address_prefixes
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
    destination_port_range                     = "22"
  }

  security_rule {
    name                                       = "CloudShell"
    priority                                   = 1001
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefix                      = "AzureCloud"
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
    destination_port_range                     = "22"
  }

  security_rule {
    name                                       = "Web"
    priority                                   = 1004
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefix                      = "*"
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.linux.id]
    destination_port_ranges                    = ["80", "443"]
  }
}

resource "azurerm_network_security_group" "windows" {
  name                = format("%s-%s-windows-nsg", local.name, local.windows_location)
  location            = local.windows_location
  resource_group_name = azurerm_resource_group.onprem.name

  security_rule {
    name                                       = "RDP"
    priority                                   = 1001
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefixes                    = local.source_address_prefixes
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
    destination_port_range                     = "3389"
  }

  security_rule {
    name                                       = "WinRm"
    priority                                   = 1002
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefixes                    = local.source_address_prefixes
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
    destination_port_ranges                    = ["5985", "5986"]
  }

  security_rule {
    name                                       = "WindowsAdminCenter"
    priority                                   = 1003
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefixes                    = local.source_address_prefixes
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
    destination_port_ranges                    = ["6516"]
  }

  security_rule {
    name                                       = "Web"
    priority                                   = 1004
    direction                                  = "Inbound"
    access                                     = "Allow"
    protocol                                   = "Tcp"
    source_address_prefix                      = "*"
    source_port_range                          = "*"
    destination_application_security_group_ids = [azurerm_application_security_group.windows.id]
    destination_port_ranges                    = ["80", "443"]
  }

  security_rule {
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
}

resource "azurerm_virtual_network" "onprem" {
  for_each            = local.vnet
  name                = each.value.name
  address_space       = [each.value.address_space]
  location            = each.value.location
  resource_group_name = azurerm_resource_group.onprem.name
}

resource "azurerm_virtual_network_peering" "to" {
  count                     = local.split_vnet ? 1 : 0
  name                      = "${local.windows_location}-to-${local.linux_location}"
  resource_group_name       = azurerm_resource_group.onprem.name
  virtual_network_name      = azurerm_virtual_network.onprem[local.windows_location].name
  remote_virtual_network_id = azurerm_virtual_network.onprem[local.linux_location].id
}

resource "azurerm_virtual_network_peering" "from" {
  count                     = local.split_vnet ? 1 : 0
  name                      = "${local.linux_location}-to-${local.windows_location}"
  resource_group_name       = azurerm_resource_group.onprem.name
  virtual_network_name      = azurerm_virtual_network.onprem[local.linux_location].name
  remote_virtual_network_id = azurerm_virtual_network.onprem[local.windows_location].id
}

resource "azurerm_subnet" "bastion" {
  for_each             = toset(var.bastion ? ["onprem"] : [])
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem[local.windows_location].name
  address_prefixes     = [azurerm_virtual_network.onprem[local.windows_location].subnets.bastion]
}

resource "azurerm_subnet" "windows" {
  name                 = "${local.name}-windows-subnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem[local.windows_location].name
  address_prefixes     = [local.vnet[local.windows_location].subnets.windows]
}

resource "azurerm_subnet" "linux" {
  name                 = "${local.name}-linux-subnet"
  resource_group_name  = azurerm_resource_group.onprem.name
  virtual_network_name = azurerm_virtual_network.onprem[local.linux_location].name
  address_prefixes     = [local.vnet[local.linux_location].subnets.linux]
}

resource "azurerm_subnet_network_security_group_association" "windows" {
  subnet_id                 = azurerm_subnet.windows.id
  network_security_group_id = azurerm_network_security_group.windows.id
}

resource "azurerm_subnet_network_security_group_association" "linux" {
  subnet_id                 = azurerm_subnet.linux.id
  network_security_group_id = azurerm_network_security_group.linux.id
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
  source              = "github.com/terraform-azurerm-modules/terraform-azurerm-arc-onprem-linux-vm?ref=v1.3"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = local.linux_location
  tags                = var.tags

  for_each = toset(local.linux_vm_names)

  name                 = each.value
  size                 = var.linux_size
  public_ip            = var.pip && !var.bastion ? true : false
  dns_label            = var.pip && !var.bastion ? "onprem-${local.uniq}-${each.value}" : null
  subnet_id            = azurerm_subnet.linux.id
  asg_id               = azurerm_application_security_group.linux.id
  admin_username       = var.admin_username
  admin_ssh_public_key = azurerm_ssh_public_key.onprem.public_key

  azcmagent = local.azcmagent.linux.install
  arc       = local.azcmagent.linux.connect ? var.arc : null
}

module "windows_vms" {
  // source              = "../terraform-azurerm-arc-onprem-windows-vm"
  source              = "github.com/terraform-azurerm-modules/terraform-azurerm-arc-onprem-windows-vm?ref=v1.3"
  resource_group_name = azurerm_resource_group.onprem.name
  location            = local.windows_location
  tags                = var.tags

  for_each = toset(local.windows_vm_names)

  name           = each.value
  size           = var.windows_size
  public_ip      = var.pip && (each.value == local.windows_vm_names[0] || !var.bastion) ? true : false
  dns_label      = var.pip && (each.value == local.windows_vm_names[0] || !var.bastion) ? "onprem-${local.uniq}-${each.value}" : null
  subnet_id      = azurerm_subnet.windows.id
  asg_id         = azurerm_application_security_group.windows.id
  admin_username = var.admin_username
  admin_password = local.windows_admin_password

  azcmagent = local.azcmagent.windows.install
  arc       = local.azcmagent.windows.connect ? var.arc : null
}

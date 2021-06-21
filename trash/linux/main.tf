terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.51.0"
    }
  }
}

locals {
  // set boolean if arc has been set
  azcmagent_connect = var.arc == {
    tenant_id                = null
    subscription_id          = null
    service_principal_appid  = null
    service_principal_secret = null
    resource_group_name      = null
    location                 = null
  } ? false : true

  // Convert map of tags to string to comma delimited key=value pairs. SPaces will be converted to underscores.
  arc_tag_value_string = join(",", [for key, value in var.arctags:
    "${replace(key, " ", "_")}=${replace(value, " ", "_")}" ])

  # Merge the arc object with the new comma delimited tags, if we're connecting
  arc = local.azcmagent_connect ? merge(var.arc, { tags = local.arc_tag_value_string}) : null

  # Accept either admin_ssh_public_key or use a file
  admin_ssh_public_key = length(var.admin_ssh_public_key) > 0 ? var.admin_ssh_public_key : file(var.admin_ssh_public_key_file)
}

data "template_cloudinit_config" "multipart" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "install_azure_cli"
    content_type = "text/cloud-config"
    content      = file("${path.module}/cloud_init/azure_cli.yaml")
  }

  part {
    filename     = "remove_azure_agent_block_imds"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_init/azure_agent_imds.tpl", { hostname = var.name })
  }

  /*
  part {
    filename     = "install_azcmagent"
    content_type = "text/cloud-config"
    content      = file("${path.module}/cloud_init/azcmagent_install.yaml")
  }

  part {
    filename     = "connect_azcmagent"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud_init/azcmagent_connect.yaml", local.arc)
  }
  */
}

resource "azurerm_public_ip" "arc" {
  name                = "${var.name}-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  allocation_method = "Static"
  domain_name_label = var.dns_label
}

resource "azurerm_network_interface" "arc" {
  name                = "${var.name}-nic"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.arc.id
  }
}

resource "azurerm_network_interface_application_security_group_association" "arc" {
  network_interface_id          = azurerm_network_interface.arc.id
  application_security_group_id = var.asg_id
}

resource "azurerm_linux_virtual_machine" "arc" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  admin_username                  = var.admin_username
  disable_password_authentication = true
  size                            = var.size

  network_interface_ids = [azurerm_network_interface.arc.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "${var.name}-os"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  // custom_data = filebase64("${path.module}/example_cloud_init")
  // custom_data = base64encode(templatefile("${path.module}/azure_arc_cloud_init.tpl", { hostname = var.name }))
  custom_data = base64encode(data.template_cloudinit_config.multipart.rendered)

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.admin_ssh_public_key
  }
}

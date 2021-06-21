variable "name" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Resource ID for a subnet."
}

variable "asg_id" {
  type        = string
  description = "Optional resource ID for an application security group"
}

variable "resource_group_name" {
  type = string
}

//=============================================================

variable "size" {
  default = "Standard_D2s_v3"
}

variable "location" {
  default = "UK South"
}

variable "tags" {
  type    = map(string)
  default = {}
}

//=============================================================

variable "admin_username" {
  default = "arcadmin"
}

variable "admin_ssh_public_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "admin_ssh_public_key" {
  default = ""
}

variable "dns_label" {
  type        = string
  default     = null
  description = "Shortname for the public IP's FQDN."
}

//=============================================================

variable "arc" {
  description = "Object desribing the service principal and resource group for the Azure Arc connected machines."
  type = object({
    tenant_id                = string
    subscription_id          = string
    service_principal_appid  = string
    service_principal_secret = string
    resource_group_name      = string
    location                 = string
  })

  default = {
    tenant_id                = null
    subscription_id          = null
    service_principal_appid  = null
    service_principal_secret = null
    resource_group_name      = null
    location                 = null
  }
}

variable "arctags" {
  description = "Map of tags used for the azcmagent. Usable default provided."
  type        = map(any)
  default = {
    platform = "arc-hack"
    os       = "linux"
  }
}

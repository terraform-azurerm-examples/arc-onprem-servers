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

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "dns_label" {
  type        = string
  default     = null
  description = "Shortname for the public IP's FQDN."
}

/* Not yet implemented
variable "generate_rdp_files" {
  type    = bool
  default = false
}

Example file:
full address:s:arcwinvm-f7a1d2eb-win1.uksouth.cloudapp.azure.com:3389
prompt for credentials:i:1
administrative session:i:1
*/

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
    os       = "windows"
  }
}

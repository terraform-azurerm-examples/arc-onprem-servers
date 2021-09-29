variable "linux_vm_names" {
  type    = list(string)
  default = []
}

variable "linux_prefix" {
  type    = string
  default = "ubuntu"
}

variable "linux_count" {
  type    = number
  default = 0
}


variable "windows_vm_names" {
  type    = list(string)
  default = []
}

variable "windows_prefix" {
  type    = string
  default = "win"
}

variable "windows_count" {
  type    = number
  default = 0
}


//========================================

# These booleans work in combination.
# The bastion boolean always determines whether the subnet, pip and bastion host are created.
# If pip is ever false then none of the VMs will get public IPs.
# If pip is true and bastion is true (default) then only the first windows VM will get a public ip (for Windows Admin Center)
# If pip is true and bastion is false then all VMs will get public IPs

variable "pip" {
  type    = bool
  default = true
}

variable "bastion" {
  type    = bool
  default = true
}

//========================================

variable "azcmagent" {
  description = "Set to control download and install the azcmagent, and connect."
  type = object({
    windows = object({
      install = bool
      connect = bool
    })
    linux = object({
      install = bool
      connect = bool
    })
  })

  default = null
}

variable "arc" {
  description = "Object describing the service principal and resource group for the Azure Arc connected machines. If azcmagent is unset then this will set all to true."
  type = object({
    tenant_id                = string
    subscription_id          = string
    service_principal_appid  = string
    service_principal_secret = string
    resource_group_name      = string
    location                 = string
    tags                     = map(string)
  })

  default = null
}

//========================================


variable "resource_group_name" {
  description = "Azure resource group name"
  default     = "onprem_servers"
}

variable "resource_prefix" {
  description = "Optional prefix string to apply to Azure resource names, e.g. DO-NOT-TOUCH"
  type        = string
  default     = null
}

variable "location" {
  description = "Azure region."
  default     = "UK South"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_username" {
  type    = string
  default = "onpremadmin"
}

variable "admin_ssh_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

variable "linux_size" {
  type    = string
  default = "Standard_A1_v2"
}

variable "windows_size" {
  type    = string
  default = "Standard_D2s_v3"
}

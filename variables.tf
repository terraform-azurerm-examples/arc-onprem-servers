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

variable "linux_size" {
  type    = string
  default = "Standard_A1_v2"
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

variable "windows_size" {
  type    = string
  default = "Standard_D2s_v3"
}

variable "create_ansible_hosts" {
  type    = bool
  default = false
}

//========================================

variable "azcmagent" {
  description = "Set to true to download and install the azcmagent."
  type        = bool
  default     = false
}

variable "arc" {
  description = "Object desribing the service principal and resource group for the Azure Arc connected machines. Requires azcmagent = true."
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
  default     = "arc-onprem-servers"
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
  default = "arcadmin"
}

variable "admin_ssh_key_file" {
  default = "~/.ssh/id_rsa.pub"
}

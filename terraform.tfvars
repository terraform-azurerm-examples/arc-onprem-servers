resource_group_name = "arc-onprem-servers"

linux_count  = 3
linux_prefix = "ubuntu"

windows_count  = 0
windows_prefix = "win"

create_ansible_hosts = true

arc = {
    tenant_id                = "72f988bf-86f1-41af-91ab-2d7cd011db47"
    subscription_id          = "2ca40be1-7e80-4f2b-92f7-06b2123a68cc"
    service_principal_appid  = "8bf0b96a-aa56-40ef-9f88-a560ae934ea4"
    service_principal_secret = "v1KbqQIm-Z3ZPvUyN3OVm6NsFdzDGrBioO"
    resource_group_name      = "arc-hack"
    location                 = "UK South"
    tags                     = {
      platform = "VMware vSphere"
      datacentre = "The Citadel"
    }
  }
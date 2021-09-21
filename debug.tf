// Linux debugging

/*
output "cloud_init" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].cloud_init }
}

output "azcmagent_download" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].azcmagent_download }
}

output "azcmagent_connect" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].azcmagent_connect }
}

output "arc" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].arc }
}

output "arc_tags_string" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].arc_tags_string }
}
*/
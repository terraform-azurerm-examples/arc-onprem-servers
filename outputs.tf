output "linux_ssh_commands" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].ssh_command }
}

output "linux_fqdns" {
  value = { for name in local.linux_vm_names :
  name => module.linux_vms[name].fqdn }
}
// Output variables

output "windows_fqdns" {
  value = { for name in local.windows_vm_names :
  name => module.windows_vms[name].fqdn }
}

output "admin_username" {
  value     = var.admin_username
}

output "windows_admin_password" {
  value     = local.windows_admin_password
  sensitive = true
}

output "uniq" {
  value = local.uniq
}

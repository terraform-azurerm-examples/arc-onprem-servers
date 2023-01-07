output "linux_ssh_commands" {
  value = {
    for name in local.linux_vm_names :
    name => "${module.linux_vms[name].ssh_command} -i ${trimsuffix(var.admin_ssh_key_file, ".pub")}"
  }
}

// output "linux_fqdns" {
//   value = { for name in local.linux_vm_names :
//   name => module.linux_vms[name].fqdn }
// }

output "windows_fqdns" {
  value = { for name in local.windows_vm_names :
  name => module.windows_vms[name].fqdn }
}

output "windows_admin_id" {
  value = var.admin_username
}

output "windows_admin_password" {
  value = local.windows_admin_password
}

output "source_address_prefixes" {
  value = local.source_address_prefixes
}

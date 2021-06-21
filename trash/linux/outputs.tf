// output "cloud_init" {
//   value = data.template_cloudinit_config.multipart.rendered
// }
//
// output "arc" {
//   value = local.arc
// }

output "fqdn" {
  value = azurerm_public_ip.arc.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.arc.ip_address
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.arc.fqdn}"
}

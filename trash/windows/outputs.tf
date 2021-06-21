output "fqdn" {
  value = azurerm_public_ip.arc.fqdn
}

output "public_ip_address" {
  value = azurerm_public_ip.arc.ip_address
}

linux_count    = 3
linux_prefix   = "ubuntu"
linux_location = "northeurope"
linux_size     = "Standard_D2as_v5"

windows_count    = 3
windows_prefix   = "win"
windows_location = "westeurope"
windows_size     = "Standard_D2s_v3"

# Specify multiple source IP addresses to open up RDP and SSH access
# Defaults to the result of `curl https://myexternalip.com/raw`
# source_address_prefixes = ["100.200.30.40","50.60.70.0/24"]

# Set pip to true to add a public IP to all VMs.
# Set pip to false if accessing the VMs over private IP via VPN/ER.
pip = true

# If both bastion and pip are true then a public IP
# will only be created for the first Windows VM
bastion = false

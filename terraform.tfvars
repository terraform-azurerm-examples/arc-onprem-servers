resource_group_name = "onprem_servers"

linux_count  = 3
linux_prefix = "ubuntu"

windows_count  = 2
windows_prefix = "win"

# Specify multiple source IP addresses to open up RDP and SSH access
# Defaults to the result of `curl https://ipinfo.io/ip`
# source_address_prefixes = ["100.200.30.40","50.60.70.80"]
source_address_prefixes = []

# Set pip to true to add a public IP to all VMs.
# Set pip to false if accessing the VMs over private IP via VPN/ER.
pip = true

# If both bastion and pip are true then a public IP
# will only be created for the first Windows VM
bastion = false

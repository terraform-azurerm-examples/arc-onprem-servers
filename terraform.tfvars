resource_group_name = "onprem_servers"

linux_count  = 3
linux_prefix = "ubuntu"

windows_count  = 3
windows_prefix = "win"

pip     = true // Only on first Windows VM if bastion = true
bastion = true

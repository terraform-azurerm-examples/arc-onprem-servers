# Azure Arc hacks

Internal only information for proctored hacks using Azure Passes.

1. Clone repo per partner
1. Generate ssh key pair using partner name
1. Create a hackteam sub and resources sub using Azure Pass
1. Create a hackteam.auto.tfvars file

     ```text
     tenant_id           = "resources_tenant_id"
     subscription_id     = "resources_subscription_id"
     resource_group_name = "onprem_servers"

     hackteam                     = "partner"
     hackteam_tenant_id           = "hackteam_tenant_id"
     hackteam_subscription_id     = "hackteam_subscription_id"
     hackteam_resource_group_name = "onprem_ssh_keys"

     admin_ssh_key_file     = "~/.ssh/partner.pub"
     windows_admin_password = "generated_password"

     source_address_prefixes = ["188.223.241.115", "167.220.0.0/16"]
     ```

#!/bin/bash
# Generates multiple hackteam.auto.tfvars files.
# Intended for internal use with multiple Azure Pass environments,
# One subscription tenant for the hackteam (Arc) to work in,
# and one for the "on premises" Resources that they will be onboarding.

# Expected structure: ~/hash/{partnername}, each with a clone of this repo

# Expected file ~/hash/partner_id, pasted from Excel with a line per partner
# partner	01234567-89ab-cdef-0123-456789abcdef	01234567-89ab-cdef-0123-456789abcdef 01234567-89ab-cdef-0123-456789abcdef 01234567-89ab-cdef-0123-456789abcdef WindowsPassword!
# where the GUIDS are the Arc tenantId and subscriptionID and then same again for the Resources sub

# Check the files are good before running terraform as there is little error trapping here!

error()
{
  tput setaf 1
  echo "ERROR: $@" >&2
  tput sgr0
  exit 1
}

info()
{
  tput setaf 6
  echo "$@" >&2
  tput sgr0
  return
}

partner=${PWD##*/}
partner=red

[[ ! -s ~/hack/partner_ids ]] && error "Expected file: ~/hack/partner_ids"

grep -v "^$" ~/hack/partner_ids | while read partner arc_tenant_id arc_subscription_id resources_tenant_id resources_subscription_id windows_admin_password etc
do
  [[ -z "$windows_admin_password" ]] && "Empty windows_admin_password."
  [[ -n "$etc" ]] && "More fields in ~/hack/partner_ids than expected."
  echo "$partner"
  [[ ! -d ~/hack/$partner ]] && error "No~/hack/$partner directory."

  cat > ~/hack/$partner/hackteam.auto.tfvars <<EOF
tenant_id           = "$resources_tenant_id"
subscription_id     = "$resources_subscription_id"
resource_group_name = "onprem_servers"

hackteam                     = "$partner"
hackteam_tenant_id           = "$arc_tenant_id"
hackteam_subscription_id     = "$arc_subscription_id"
hackteam_resource_group_name = "onprem_ssh_keys"

admin_ssh_key_file     = "~/.ssh/$partner.pub"
windows_admin_password = "$windows_admin_password"

# source_address_prefixes = ["123.234.123.234", "167.220.0.0/16"]
EOF
done

exit 0

#!/bin/bash
# Generates multiple hackteam.auto.tfvars files.
# Intended for internal use with multiple Azure Pass environments,
# One subscription tenant for the hackteam (Arc) to work in,
# and one for the "on premises" Resources that they will be onboarding.

# Expected structure: ~/hash/{hackteam}, each with a clone of this repo

# Expected file ~/hash/hackteams, pasted from Excel with a line per team
# hackteam	01234567-89ab-cdef-0123-456789abcdef	01234567-89ab-cdef-0123-456789abcdef 01234567-89ab-cdef-0123-456789abcdef 01234567-89ab-cdef-0123-456789abcdef WindowsPassword!
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

[[ $1 = "azcmagent" ]] && azcmagent=true || azcmagent=false

[[ ! -s ~/hack/hackteams ]] && error "Expected file: ~/hack/hackteams"

grep -v "^$" ~/hack/hackteams | while read hackteam arc_tenant_id arc_subscription_id resources_tenant_id resources_subscription_id windows_admin_password etc
do
  [[ -z "$windows_admin_password" ]] && "Empty windows_admin_password."
  [[ -n "$etc" ]] && "More fields in ~/hack/hackteams than expected."

  echo "$hackteam"
  [[ ! -d ~/hack/$hackteam ]] && error "No ~/hack/$hackteam directory."

  [[ ! -d ~/.ssh ]] && mkdir -m 700 ~/.ssh
  if [[ ! -s ~/.ssh/$hackteam.pub ]]
  then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/$hackteam -N ""
    chmod 600 ~/.ssh/$hackteam
    chmod 644 ~/.ssh/$hackteam.pub
    info "- Created ~/.ssh/$hackteam and ~/.ssh/$hackteam.pub"

  fi

  cat > ~/hack/$hackteam/hackteam.auto.tfvars <<HACKTEAM
tenant_id           = "$resources_tenant_id"
subscription_id     = "$resources_subscription_id"
resource_group_name = "onprem_servers_$hackteam"

hackteam                     = "$hackteam"
hackteam_tenant_id           = "$arc_tenant_id"
hackteam_subscription_id     = "$arc_subscription_id"
hackteam_resource_group_name = "onprem_ssh_keys"

admin_ssh_key_file     = "~/.ssh/$hackteam.pub"
windows_admin_password = "$windows_admin_password"

source_address_prefixes = ["90.219.168.11","86.7.173.94"]
HACKTEAM
  info "- Variable file ~/hack/$hackteam/hackteam.auto.tfvars"

  if $azcmagent
  then

    # Resource group for the Arc-enabled Servers, i.e. connected machines
    resource_group_name=azure_arc_$hackteam
    location=uksouth

    ## Create resource group

    az group create --name $resource_group_name --location $location --subscription $arc_subscription_id --output none || error "Failed to create $resource_group_name"
    resource_group_id=$(az group show --name $resource_group_name --subscription $arc_subscription_id --query id --output tsv)
    info "- Resource group $resource_group_name"

    # Create the service principal and role assignment

    name=azure_arc_$hackteam
    json=$(az ad sp create-for-rbac --name $name --scope $resource_group_id --role "Azure Connected Machine Onboarding" --only-show-errors)
    info "- Service principal $name"

    # Create the default auto.*.tfvars file, sending to stdout.
    # Calling program should redirect to file. User can modify before running Terraform.

    cat > ~/hack/$hackteam/azcmagent.auto.tfvars <<AZCMAGENT
azcmagent = {
  windows = {
    install = true
    connect = true
  }
  linux = {
    install = true
    connect = true
  }
}

arc = {
  tenant_id                = "$(jq -r .tenant <<< $json)"
  service_principal_appid  = "$(jq -r .appId <<< $json)"
  service_principal_secret = "$(jq -r .password <<< $json)"

  subscription_id          = "$arc_subscription_id"
  resource_group_name      = "$resource_group_name"
  location                 = "$location"

  tags = {
    hackteam    = "$hackteam"
    description = "training"
  }
}
AZCMAGENT

    info "- Variable file ~/hack/$hackteam/azcmagent.auto.tfvars"
  fi

done

exit 0

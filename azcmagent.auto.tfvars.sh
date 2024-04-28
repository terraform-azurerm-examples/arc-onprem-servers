#!/bin/bash
# Script intended for a single environment.
# (Use the hackteam.auto.tfvars.sh script for multiple environments.)
#
# Can set resource group name in the first argument.
# Can set subscription id in the second argument.
# Can set location in the third argument.
#
# Assumes that the user is in the right context and has the right permissions.
# The script creates a service principal and role assignment for the Azure Connected Machine Onboarding role.
# The script creates the azcmagent.auto.tfvars file for the Azure Arc Connected Machine agent installation.
# The script creates a resource group for the Arc-enabled Servers, i.e. connected machines.

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

## Variables

resource_group_name=${1:-arc_pilot}
[[ -n "$2" ]] && subscription_id=$2 || subscription_id=$(az account show --query id --output tsv)
[[ -n "$3" ]] && location=$3 || location=uksouth

info "- Creating resource group $resource_group_name"
az group create --name $resource_group_name --location $location --subscription $subscription_id --output none || error "Failed to create $resource_group_name"
resource_group_id=$(az group show --name $resource_group_name --subscription $subscription_id --query id --output tsv)

# Create the service principal and role assignment

name=$resource_group_name
info "- Creating service principal $name"
json=$(az ad sp create-for-rbac --name $name --scope $resource_group_id --role "Azure Connected Machine Onboarding" --only-show-errors)

# Create the azcmagent.auto.tfvars file

cat > azcmagent.auto.tfvars <<EOF
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

  subscription_id          = "$subscription_id"
  resource_group_name      = "$resource_group_name"
  location                 = "$location"
  tags = {
    environment = "pilot"
  }
}

EOF

info "- Created azcmagent.auto.tfvars variable file. Check before running Terraform."

#!/bin/bash

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

# Resource group for the Arc-enabled Servers, i.e. connected machines
subscription_id=$(az account show --query id --output tsv)
resource_group_name=arc_pilot
location=uksouth

## Create resource group

info "Creating resource group $resource_group_name"
az group create --name $resource_group_name --location $location --output jsonc || error "Failed to create $resource_group_name"
resource_group_id=$(az group show --name $resource_group_name --query id --output tsv)

# Create the service principal and role assignment

# name=arc_pilot_$(sha1sum <<< $resource_group_id | cut -c1-8)
name=arc_pilot
info "Creating service principal $name"
json=$(az ad sp create-for-rbac --name $name --scope $resource_group_id --role "Azure Connected Machine Onboarding" --only-show-errors)
jq -r <<< $json

# Create the auto.*.tfvars file

cat > azcmagent.auto.tfvars <<EOF
azcmagent = true

arc = {
  tenant_id                = "$(jq -r .tenant <<< $json)"
  service_principal_appid  = "$(jq -r .appId <<< $json)"
  service_principal_secret = "$(jq -r .password <<< $json)"

  subscription_id          = "$subscription_id"
  resource_group_name      = "$resource_group_name"
  location                 = "$location"

  tags = {
    platform   = "VMware vSphere"
    cluster    = "POC"
  }
}

EOF

info "Created azcmagent.auto.tfvars:"
cat azcmagent.auto.tfvars
# arc-onprem-servers

This READMORE includes additional information not coveredsin the [README](./README.md), with additional detail on variables, defaults, and the optional azcmagent and arc variables for automated agent download and Arc onboarding.

## Variables

The variables are shown with their default value.

* `linux_count = 0`
* `linux_prefix = "ubuntu"`

    Use in combination to generate an array of linux VM names. If linux_count = 2 then the array = ["ubuntu-01","ubuntu-02"].

* `windows_count = 0`
* `windows_prefix = "win"`

    Does the same for windows VM names. Note that "windows" is not a permitted prefix as it is a trademarked word.

* `linux_vm_names = []`
* `windows_vm_name = []`

    Use these to explicitly set the individual names. Overrides the count and prefix values.

    E.g.: `linux_vm_names = ["red","blue"]`

* `resource_group_name = onprem_servers`
* `location = "UK South"`
* `tags = {}`
* `admin_username = onpremadmin`
* `resource_prefix = ""`

## azcmagent

### Manual azcmagent installation

You can SSH to the VM and install the [azcmagent](https://docs.microsoft.com/azure/azure-arc/servers/agent-overview#linux-agent-installation-details) manually.

### Automated azcmagent installation

If you want this Terraform repo to automatically download and install the azcmagent then set:

* `azcmagent = true`

## Connecting to Azure Arc

### Manual onboarding

There are a number of ways of connecting:

* <https://docs.microsoft.com/azure/azure-arc/servers/agent-overview#installation-and-configuration>

### Scale onboarding

If you want this Terraform repo to automatically connect the VM to Azure Arc then you will need a service principal with the Azure Connected Machine Onboarding role on a resource group.

Specify the following object in terraform.tfvars:

```hcl
arc = {
    tenant_id                = "tenant"
    service_principal_appid  = "appId"
    service_principal_secret = "password"

    subscription_id     = "subscriptionId"
    resource_group_name = "arc_pilot"
    location            = "uksouth"

    tags = {
      platform   = "vSphere"
      datacentre = "Citadel"
      location   = "Reading"
    }
  }
```

The subscription ID, resource group name and location are for the onboarded (or connected) VMs. _Do not confuse with the "on prem" Azure VMs created by this repo._

The tenant, appId and password are the values from `az ad sp create-for-rbac`.

Example command to configure a service principal that has the onboarding role on a resource group:

```bash
rgid=$(az group create --name arc_pilot --location uksouth --query id --output tsv)
az ad sp create-for-rbac --role "Azure Connected Machine Onboarding" --scopes $rgid --output jsonc
```

The tags and their values are included as an example. If the tag values include any spaces then they will be converted to underscores.

Note that if you set the arc object then azcmagent will be set to true automatically.

### Automated onboarding

An azcmagent.auto.tfvars.sh script is included that will

1. Create a resource group
1. Create a service principal
1. Assign the Azure Connected Machine Onboarding role to the resource group
1. Generates an azcmagent.auto.tfvars file

The azcmagent.auto.tfvars will work alongside your terraform.tfvars, so that the on prem VMs in the Terraform deployment will

1. Download and install azcmagent
1. Connect the VM to Azure using the service principal

If you then run the terraform workflow again then your VMs should be automatically onboarded.

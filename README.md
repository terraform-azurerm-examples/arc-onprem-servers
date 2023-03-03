# arc-onprem-servers

Repository to create "on prem" VMs for onboarding to Azure Arc.

If the attendees have another source of on prem servers (e.g. a VMware vSphere cluster) then they can use VMs from there. If they don't then this can provide some on prem VMs that can be onboarded to Azure Arc as if they existed outside of Azure. The modules block the IMDS and remove the Azure Agent to fool the azcmagent into thinking they aren't Azure VMs.

This README covers the standard use. The [READMORE](./READMORE.md) includes additional detail on variables, defaults, and the optional azcmagent and arc variables for automated agent download and Arc onboarding.

## Overview

The repo will create an "onprem_servers" resource group and a number of resources.

Operating systems available:

| OS | Admin User | Admin Credentials |
|---|---|---|
| Ubuntu Server 18.04 LTS | onpremadmin | Uses the default [SSH key pair](https://docs.microsoft.com/azure/virtual-machines/linux/mac-create-ssh-keys) unless specified |
| Windows Server 2019 | onpremadmin | Terraform output displays the admin password |

**You will need an SSH key pair**: <https://docs.microsoft.com/azure/virtual-machines/linux/mac-create-ssh-keys>

It will also create a vNet and a custom NSG (using ASGs) to control the ports opened up to the Windows and Linux VMs. Note that these VMs are intended for training and demo purpose only and expose ports that should not be exposed for production workloads.

## Azure Agent and IMDS Endpoint

The provisioned servers are customised to remove the Azure Agent and to block the internal http endpoint for the Instance Metedata Service (IMDS). If the Azure agent and IMDS endpoint on the VM were visible to the azcmagent installation then it would abort.

The servers can then be onboarded to Azure by downloading azcmagent and connecting as per the [Azure docs](https://aka.ms/AzureArcDocs).

> You should not need to touch the resources that Terraform creates in the `onprem_servers` resource group.

Consider these servers to be on prem servers for Azure Arc onboarding practice. Do not treat as normal Azure VMs!

## Prepare

1. Create a new SSH keypair
1. Login

    Login to Azure and check you are in the correct subscription context.

    ```bash
    az login
    ```

1. Clone

   ```bash
   git clone https://github.com/terraform-azurerm-examples/arc-onprem-servers/
   ```

1. Directory

    Change directory to the root module.

    ```bash
    cd arc-onprem-servers
    ```

1. Edit terraform.tfvars (optional)

    Modify the terraform.tfvars as required. The default values will create three Ubuntu VMs and two Windows VMs.

    The default settings for the pip and bastion boolean variables will create public IPs resource on all VMs.

    > Customise if you prefer to use Bastion or you plan to add private networking access via VPN / ExpressRoute. Note that setting both to true will only create a public IP for the first Windows server - for Windows Admin Center access.

    The module will automatically add your source IP address to the NSGs for RDP / SSH access to the public IPs.

    Set it manually if you require more than one source IP address or if you are running on remote compute e.g. a Cloud Shell container.

    1. Find your source IP address

        Go to https://ipinfo.io, or https://myexternalip.com/raw.

        ```bash
        curl https://myexternalip.com/raw
        ```

    1. Add to source_address_prefixes

        For example:

        ```text
        source_address_prefixes = ["68.321.97.64","86.158.18.94"]
        ```

    Additional variables are defined in variables.tf with sensible defaults.

## Deploy

Run through the standard Terraform workflow.

1. Initialise

    Initialise Terraform to check syntax and then download the providers and modules.

    ```bash
    terraform init
    ```

1. Plan

    Evaluate the variables, config files and current state and display the planned additions, deletions and changes.

    ```bash
    terraform plan
    ```

1. Apply

    Deploy the environment.

    ```bash
    terraform apply
    ```

    A successful deployment will display `Apply complete!` and display the outputs.

## Confirmation

There is a possibility that your session will timeout if you are using the Cloud Shell. If so then run another plan.

```bash
terraform plan
```

If everything has been created then `terraform plan` will display that there are no planned changes.

```text
No changes. Your infrastructure matches the configuration.
```

If the output shows that there are planned changes then run another apply.

```bash
terraform apply
```

Terraform should apply the remaining changes to reach the desired state.

## Output

The terraform apply will show the outputs, such as FQDNs and SSH commands. To redisplay:

```bash
terraform output
```

The Windows admin password is a "sensitive value". To display its value:

```bash
terraform output windows_admin_password
```

> These commands will only show output if you are in the directory of the Terraform repo.

## Destroy

When you no longer need the resources then you can either remove the whole resource group or run:

```bash
terraform destroy
```

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

## Deployment

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

    Modify the terraform.tfvars as required. The default values will create three VMs of each type.

    The default settings for pip and bastion will create an Azure Bastion service to securely connect to the VMs over SSH and RDP. It will add a single public IP to the first Windows VM for Windows Admin Center access over the FQDN.

    * If you are not planning to use Windows Admin Center then set pip to false.
    * If you would rather use public IPs on all hosts rather than Bastion (cheaper, less secure) then set bastion = false and pip = true
    * For fully secure access then you have the option to add hybrid networking connectivity (e.g. P2S to a VPN Gateway) and setting both to false.

    Additional variables are defined in variables.tf with sensible defaults.

1. Deploy

    Run through the standard Terraform workflow.

    ```bash
    terraform init
    terraform validate
    terraform plan
    terraform apply
    ```

    If there are any errors then rerun the `terraform apply` and Terraform should create remaining resources.

    Once everything has been created then `terraform plan` should display

    ```text
    No changes. Infrastructure is up-to-date.
    ```

## Output

Use `terraform output` to show FQDNs and SSH commands.

> This will only show output if you are in the Terraform directory.

The Windows admin password is a "sensitive value". Use `terraform output windows_admin_password` to display the value.

## Removal

To remove the resources:

```bash
terraform destroy
```

# Azure Arc hacks

Information for proctored hacks

1. Create a hack folder in your home directory

    ```shell
    mkdir ~/hack && cd ~/hack
    ```

1. Clone repo per hackteam

    ```bash
    git clone https://github.com/terraform-azurerm-examples/arc-onprem-servers hackteam
    ```

    Repeat for each team.

1. Create the hackteams file

  Whitespace delimited file. One row per team.

  Fields:
  - hackteam
  - hackteam's tenant ID
  - hackteam's subscription ID
  - on premises tenant ID
  - on premises subscription ID
  - Windows Admin Password

1. Run the hackteam.auto.tfvars.sh in any hackteam directory to

  - generate SSH keys if missing
  - create the hackteam.auto.tfvars variable file
  - create the azcmagent.auto.tfvars variable file (if azcmagent if used as first argument)

#cloud-config
#
# This is an cloud-init file to install the azcmagent.
#
#
#
# Stop the walinux agent and b) configure the firewall to block the Instance Metadata Service.
#
# This allows azcmagent to be installed and the VM to be onboarded to Azure Arc
# as if it was an on prem virtual machine.
#
# Don't create files in /tmp during the early stages that cloud-init works in. Use /var/run.
# Generated runcmd script run as root: sudo cat /var/lib/cloud/instance/scripts/runcmd
# Cloud-init output: cat /var/log/cloud-init-output.log
merge_how:
 - name: list
   settings: [append]
 - name: dict
   settings: [no_replace, recurse_list]

cloud_config_modules:
  - runcmd
cloud_final_modules:
  - scripts-user

runcmd:
 - echo "Starting azure arc runcmd steps at $(date +%H:%M:%C)"
 - echo "Configuring walinux agent"
 - service walinuxagent stop
 - waagent deprovision force
 - rm -fr /var/lib/waagent
 - echo "Configuring Firewall"
 - ufw --force enable
 - ufw deny out from any to 169.254.169.254
 - ufw default allow incoming
 - echo "Configuring hostname to ${hostname}"
 - hostname ${hostname}
 - echo ${hostname} > /etc/hostname
 - echo "Finished azure arc runcmd steps at $(date +%H:%M:%C)"

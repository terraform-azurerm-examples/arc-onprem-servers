[arc_hack_linux_vms]
%{ for fqdn in linux_fqdns ~}
${fqdn}
%{ endfor ~}

[arc_hack_linux_vms:vars]
ansible_user=${username}

[arc_hack_windows_vms]
%{ for fqdn in windows_fqdns ~}
${fqdn}
%{ endfor ~}

[arc_hack_windows_vms:vars]
ansible_user=${username}
ansible_password="${password}"
ansible_connection=winrm
ansible_winrm_transport=basic
ansible_port=5985
ansible_winrm_server_cert_validation=ignore

Start-Transcript -Path C:\Terraform\winrm_https_imds.log

Write-Host "Delete any existing WinRM listeners"
winrm delete winrm/config/listener?Address=*+Transport=HTTP  2>$Null
winrm delete winrm/config/listener?Address=*+Transport=HTTPS 2>$Null

Write-Host "Create a new self signed certificate"
$Cert = New-SelfSignedCertificate -DnsName ${fqdn}, ${name} `
    -CertStoreLocation "cert:\LocalMachine\My" `
    -FriendlyName "Self Signed WinRM Cert"

$Thumbprint = $Cert.Thumbprint
$Cert | Out-String


Write-Host "Create a new HTTP WinRM listener"
winrm create winrm/config/listener?Address=*+Transport=HTTP

Write-Host "Create a new HTTPS WinRM listener"
$WinRmHttps = "@{Hostname=`"${fqdn}`"; CertificateThumbprint=`"$Thumbprint`"}"
winrm create winrm/config/listener?Address=*+Transport=HTTPS

Write-Host "Configure WinRM settings"
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

Write-Host "Configure UAC to allow privilege elevation in remote shells"
$Key = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

Write-Host "Turn off PowerShell execution policy restrictions"
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine

Write-Host "Stop the WinRM Service and set to start automatically"
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic

Write-Host "Enable the required firewall exceptions for WinRM"
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
netsh advfirewall firewall add rule name="Windows Remote Management (HTTPS-In)" dir=in action=allow protocol=TCP localport=5986

Write-Host "Block the Azure Instance Metadata Service"
netsh advfirewall firewall add rule name="Block Azure IMDS" action=block localip=any dir=out remoteip=169.254.169.254

Write-Host "Start up WinRM"
Start-Service -Name WinRM

Stop-Transcript

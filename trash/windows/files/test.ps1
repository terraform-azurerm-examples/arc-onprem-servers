# PowerShell test file

# Set-ExecutionPolicy Bypass -Scope Process -Force

$Today = (Get-Date).DateTime
Write-Host $Today ": Test Script"

# Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
# Stop-Service WindowsAzureGuestAgent -Force -Verbose

exit 0
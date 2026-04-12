# This script runs via Custom Script Extension to prepare the VM
# and upload DSC configuration

Write-Host "Starting VM initialization..."

# Create temp directory
$tempDir = "C:\temp"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Enable WinRM for DSC
Write-Host "Enabling WinRM..."
winrm quickconfig -q
Enable-PSRemoting -Force -ErrorAction SilentlyContinue | Out-Null

# Set execution policy
Write-Host "Setting execution policy..."
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

Write-Host "VM initialization completed."
Write-Host "DSC will be applied via the DSC Extension..."

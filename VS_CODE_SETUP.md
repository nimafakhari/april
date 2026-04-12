# VS Code Azure Setup Guide

## Step 1: Install Required Extensions

Install these extensions in VS Code:

1. **Azure Account** - ms-vscode.azure-account
2. **Azure Tools** - ms-vscode.vscode-node-azure-pack (includes 10 Azure extensions)
3. **Terraform** - HashiCorp.terraform
4. **PowerShell** - ms-vscode.PowerShell
5. **REST Client** (optional) - humao.rest-client

Or install from terminal:
```powershell
code --install-extension ms-vscode.azure-account
code --install-extension ms-vscode.vscode-node-azure-pack
code --install-extension HashiCorp.terraform
code --install-extension ms-vscode.PowerShell
```

## Step 2: Authenticate with Azure

1. Open VS Code
2. Press `Ctrl+Shift+P` → "Azure: Sign In"
3. Browser opens → Login with your Azure account
4. Return to VS Code → You'll see "Signed in" confirmation
5. Explorer sidebar shows your subscriptions and resources

## Step 3: Configure Terraform Extension

1. Go to VS Code Settings (`Ctrl+,`)
2. Search: "terraform"
3. Configure:
   - **Terraform: Path**: `terraform` (or full path if not in PATH)
   - **Terraform: Format on Save**: ✓ Check
   - **Terraform: Validate on Save**: ✓ Check

## Step 4: Verify Azure CLI

```powershell
# Check if Azure CLI is installed
az --version

# If not installed, install it:
# Download from: https://aka.ms/azurecli
# Or use: choco install azure-cli
```

## Step 5: Set VS Code to Use Your Subscription

1. In Explorer, click Azure icon (should show subscriptions)
2. Right-click your subscription → "Set as Default Subscription"
3. This tells Terraform and CLI tools which subscription to use

## Step 6: Working with Terraform in VS Code

### Open Terraform Files
- Open `new/terraform/` folder in VS Code
- Files will have syntax highlighting and validation

### Run Terraform Commands from Terminal
```powershell
# Open integrated terminal: Ctrl+`

cd terraform/

# Initialize
terraform init

# Validate
terraform validate

# Format
terraform fmt

# Plan
terraform plan

# Apply
terraform apply
```

### Debug Terraform Issues
Open VS Code Debug Console while editing Terraform files for better diagnostics.

## Step 7: View Azure Resources in VS Code

1. **Azure Explorer** (left sidebar) shows:
   - Your subscriptions
   - Resource groups
   - Virtual Machines
   - Storage accounts
   - Other resources

2. **Right-click actions**:
   - Create resource
   - Deploy
   - View properties
   - Remote SSH to VM

## Step 8: Monitor Deployment

### Via VS Code Azure Explorer:
1. Expand subscription
2. Find resource group: `rg-python-redis-dev`
3. Expand → View VMs, storage, networking
4. Right-click VM → "Connect via SSH" or "Open in Portal"

### Via Terminal:
```powershell
# Watch deployment progress
az deployment group show -g rg-python-redis-dev -n <deployment-name> --query 'properties.outputs'

# List resources in group
az resource list -g rg-python-redis-dev --output table
```

## Step 9: Connect to Your VM Remotely

### Option A: Via Bastion (Recommended - no public IP)
1. Create Azure Bastion resource
2. In VS Code Azure Explorer → Right-click VM → "Connect"

### Option B: Via RDP (requires public IP or VPN)
1. Get VM IP: `terraform output vm_private_ip`
2. Open RDP client: `mstsc`
3. Enter IP address
4. Use admin credentials from `terraform.tfvars`

### Option C: Via PowerShell Remoting
```powershell
$vmIp = (terraform output -raw vm_private_ip)
$cred = Get-Credential  # Use admin credentials

$session = New-PSSession -ComputerName $vmIp -Credential $cred -UseSSL

# Then use: Invoke-Command -Session $session -ScriptBlock { ... }
```

## Step 10: Useful VS Code Extensions for DevOps

| Extension | Use Case |
|-----------|----------|
| Azure Storage | Manage storage accounts |
| Azure Database | Manage databases |
| Azure App Service | Deploy web apps |
| Rest Client | Test APIs |
| Docker | Manage containers |
| Remote - SSH | SSH to machines |

## Troubleshooting

### "Terraform not found"
```powershell
# Install Terraform
choco install terraform
# Or download from: https://www.terraform.io/downloads

# Verify
terraform --version
```

### "Azure CLI not found"
```powershell
choco install azure-cli
# Or: https://aka.ms/azurecli
az --version
```

### "Not signed into Azure"
```powershell
# In VS Code: Ctrl+Shift+P → "Azure: Sign In"
# Or terminal: az login
```

### "Extension errors in VS Code"
1. `Ctrl+Shift+X` → Extensions
2. Find extension → Reload
3. Close and reopen VS Code
4. Check output: View → Output → Select extension name

## Quick Reference: Common Commands

```powershell
# Terraform
terraform init          # Initialize
terraform validate      # Check syntax
terraform plan         # Preview changes
terraform apply        # Deploy
terraform destroy      # Delete everything
terraform output       # Show outputs

# Azure CLI
az login              # Authenticate
az group list         # List resource groups
az vm list -g <rg>   # List VMs in group
az vm start -g <rg> -n <vm>    # Start VM
az vm stop -g <rg> -n <vm>     # Stop VM
az vm delete -g <rg> -n <vm>   # Delete VM
```

## Next: Deploy Your Infrastructure

1. Update `terraform/terraform.tfvars` with your subscription ID and password
2. Open Terminal: `Ctrl+``
3. Run: `cd terraform && terraform init && terraform plan`
4. Review the plan
5. Run: `terraform apply`
6. Wait 5-10 minutes for deployment
7. Access your app via `terraform output app_access_url`

---

Happy deploying! 🚀

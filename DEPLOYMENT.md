# Azure Deployment for Python Redis App

Complete infrastructure-as-code setup using Terraform and PowerShell DSC to deploy Python 3.11 app with Redis on Windows VM.

## Architecture

- **Resource Group**: Container for all Azure resources
- **Virtual Network**: Private 10.0.0.0/16 (no public IP)
- **Windows VM**: Standard_B1s (small test VM)
- **Redis**: Installed on the same VM running on port 6379
- **Python App**: HTTP server on port 8000 with Redis counter
- **Network Security**: Only internal VNet access allowed

## Prerequisites

1. **Azure Account** with active subscription
2. **Azure CLI** installed and authenticated
3. **Terraform** (v1.0+) installed
4. **VS Code Extensions**:
   - Azure Account
   - Azure Tools
   - Terraform
   - PowerShell

## Setup Steps

### 1. Connect Azure CLI to Your Subscription

```powershell
# Login to Azure
az login

# List subscriptions
az account list --output table

# Set default subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"
```

### 2. Update Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
azure_subscription_id = "YOUR_SUBSCRIPTION_ID_HERE"
admin_password = "YourSecurePassword!1234"
# Optional: change location, vm names, sizes, etc.
```

**Important**: Keep `admin_password` secure. Consider using Azure Key Vault instead:

```bash
# Alternative: Use sensitive variables (more secure)
terraform apply -var-file="terraform/terraform.tfvars" -var="admin_password=$(az keyvault secret show --vault-name MyKeyVault -n VmPassword --query value -o tsv)"
```

### 3. Initialize Terraform

```powershell
cd terraform/

# Initialize working directory
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive
```

### 4. Plan and Apply Infrastructure

```powershell
# Create execution plan
terraform plan -out=tfplan

# Review the plan output carefully!

# Apply the plan
terraform apply tfplan

# Save outputs
terraform output -json > outputs.json
```

### 5. Access Your VM

After deployment (5-10 minutes), get the VM's private IP:

```powershell
# Get VM private IP
$vmIp = terraform output -raw vm_private_ip
Write-Host "VM Private IP: $vmIp"

# Access via RDP (requires VPN or Bastion on same VNet)
# mstsc /v:$vmIp

# Or SSH if you configure it
```

### 6. Test the Application

From within the VNet (or via Bastion/VPN):

```powershell
# Get the app URL
$appUrl = terraform output -raw app_access_url
Write-Host "App URL: $appUrl"

# Test HTTP access
Invoke-WebRequest -Uri $appUrl -UseBasicParsing

# Or from inside the VM via PowerShell:
Invoke-WebRequest -Uri "http://localhost:8000" -UseBasicParsing
```

## Troubleshooting

### Check DSC Extension Status

```powershell
# On the VM (via RDP)
Get-DscLocalConfigurationManager
Get-DscConfiguration
```

### View Extension Logs

```powershell
# In Azure Portal:
# VM > Extensions + applications > DSC

# Or via PowerShell:
$resourceGroup = "rg-python-redis-dev"
$vmName = "vm-python-redis-app"

$extension = Get-AzVMExtension -ResourceGroupName $resourceGroup -VMName $vmName -Name "DSC"
$extension.ProvisioningState
```

### Verify Services

```powershell
# RDP into the VM and run:
Get-Service Redis
Get-Process python

# Check if python app is running
Get-ScheduledTask -TaskName "StartPythonApp" | Select-Object -Property TaskName, State
```

### Check Redis Connection

```powershell
# On the VM
redis-cli ping
# Should return: PONG

# Test counter app
redis-cli incr my_counter
redis-cli get my_counter
```

## Key Files

| File | Purpose |
|------|---------|
| `terraform/main.tf` | Main resource definitions |
| `terraform/variables.tf` | Input variables |
| `terraform/terraform.tfvars` | Variable values |
| `terraform/outputs.tf` | Output values |
| `dsc/dsc_config.ps1` | PowerShell DSC configuration |
| `dsc/InitSetup.ps1` | VM initialization script |

## Next Steps

### Add Public Access (if needed later)

1. Create Azure Bastion for secure RDP access
2. Or: Add Public IP to network interface
3. Or: Set up VPN gateway

### Monitoring & Logging

```powershell
# Enable diagnostics
# Via Portal: VM > Diagnostic settings > Add diagnostic setting
# Select metrics and logs to monitor
```

### Security Improvements

1. Use Azure Key Vault for passwords
2. Enable Azure Disk Encryption
3. Configure NSG rules more restrictively
4. Implement MFA on Azure account

### Scaling

- Create VM image from configured VM
- Use Terraform modules for reusability
- Add Terraform state in Azure Storage (avoiding local state)

## Terraform State Management

**Important**: By default, Terraform stores state locally in `terraform.tfstate`. For team environments:

```powershell
# Create Terraform backend in Azure Storage
az storage account create -n "tfstate$env:USERNAME" -g rg-terraform -l eastus --sku Standard_LRS
az storage container create -n tfstate --account-name "tfstate$env:USERNAME"

# Create backend.tf:
# terraform {
#   backend "azurerm" {
#     resource_group_name  = "rg-terraform"
#     storage_account_name = "tfstate..."
#     container_name       = "tfstate"
#     key                  = "prod.terraform.tfstate"
#   }
# }
```

## Cleanup

```powershell
# Destroy all resources
terraform destroy

# Confirm deletion - this removes everything!
```

## Additional Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure DSC Documentation](https://learn.microsoft.com/en-us/azure/automation/extension-based-dsc-overview)
- [Terraform Best Practices](https://learn.hashicorp.com/tutorials/terraform/best-practices)

---

**Note**: This setup demos a simple deployment. For production, add:
- SSL/TLS certificates
- Load balancing
- Auto-scaling
- More restrictive security policies
- Backup & disaster recovery

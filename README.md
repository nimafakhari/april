# Python Redis App - Azure Deployment

Complete end-to-end infrastructure deployment with Terraform and PowerShell DSC for a Python 3.11 web application with Redis.

## 📋 Project Overview

This project demonstrates:
- **Infrastructure as Code (IaC)** using Terraform
- **Configuration Management** with PowerShell DSC
- **Azure cloud deployment** for Windows VM
- **Python application** with Redis backend
- **Network security** with private VNet (no public IP)

### What Gets Deployed

```
Azure Subscription
├── Resource Group (rg-python-redis-dev)
│   ├── Virtual Network (10.0.0.0/16)
│   │   └── Subnet (10.0.1.0/24)
│   ├── Windows VM (Standard_B1s)
│   │   ├── Python 3.11
│   │   ├── Redis service
│   │   └── Web app (port 8000)
│   ├── Network Interface (private IP)
│   ├── Network Security Group (firewall rules)
│   └── Storage Account (DSC artifacts)
```

## 🚀 Quick Start (5 minutes)

### Prerequisites

- Azure subscription (with valid credentials)
- Terraform installed (`terraform --version` should work)
- Azure CLI installed (`az --version` should work)

### Deploy in 3 Steps

```powershell
# 1. Validate setup
.\validate-deployment.ps1

# 2. Initialize and preview
cd terraform
terraform init
terraform plan

# 3. Deploy
terraform apply
# Answer: yes (when prompted)
```

After 5-10 minutes, your app will be running!

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| **[DEPLOYMENT.md](DEPLOYMENT.md)** | Complete deployment guide with troubleshooting |
| **[VS_CODE_SETUP.md](VS_CODE_SETUP.md)** | VS Code Azure integration & extension setup |
| **[README.md](README.md)** | This file - project overview |

## 📁 Project Structure

```
new/
├── app.py                    # Python web application (Redis counter)
├── requirements.txt          # Python dependencies (redis)
├── Dockerfile               # Docker configuration (reference)
├── docker-compose.yml       # Docker compose (reference)
├── 
├── terraform/               # ⭐ Terraform Infrastructure Code
│   ├── main.tf             # Main resource definitions
│   ├── variables.tf        # Input variable declarations
│   ├── outputs.tf          # Output values
│   ├── terraform.tfvars    # Variable values (customize this!)
│   └── .terraform/          # Generated (ignore)
├── 
├── dsc/                     # ⭐ PowerShell Desired State Configuration
│   ├── dsc_config.ps1      # DSC configuration (sets up VM)
│   └── InitSetup.ps1       # VM initialization script
├── 
├── DEPLOYMENT.md            # Detailed deployment guide
├── VS_CODE_SETUP.md         # VS Code setup instructions
└── validate-deployment.ps1  # Quick validation script
```

## 🔧 Configuration

### Main Settings (terraform/terraform.tfvars)

```hcl
# REQUIRED - Get from: az account show --query id -o tsv
azure_subscription_id = "YOUR_SUBSCRIPTION_ID_HERE"

# VM Admin credentials (Windows login)
admin_username = "azureuser"
admin_password = "P@ssw0rd!Azure2024"    # Change this!

# Infrastructure naming
resource_group_name = "rg-python-redis-dev"
vm_name = "vm-python-redis-app"

# VM size for cost savings
vm_size = "Standard_B1s"                 # Small test VM

# Network configuration (private, no public IP)
vnet_address_space = ["10.0.0.0/16"]
subnet_address_prefixes = ["10.0.1.0/24"]

# Application ports
app_port = 8000                          # Python app
redis_port = 6379                        # Redis database
```

### Key Parameters Explained

| Parameter | Value | Why |
|-----------|-------|-----|
| OS | Windows Server 2022 | DSC support, enterprise ready |
| VM Size | Standard_B1s | Lowest cost for testing |
| Public IP | None | Internal only (secure) |
| Python | 3.11-slim | Matches Docker image |
| Redis | Community Edition | Single instance test |
| Network | Private VNet | No exposure to internet |

## 🛠️ Common Tasks

### Get Your Application URL

```powershell
cd terraform
terraform output app_access_url
# Output: http://10.0.1.45:8000

# Test from within VNet:
Invoke-WebRequest -Uri (terraform output -raw app_access_url)
```

### Connect to VM via RDP

```powershell
$vmIp = terraform output -raw vm_private_ip
mstsc /v:$vmIp
# Credentials: azureuser / (password from tfvars)
```

### Check Deployment Status

```powershell
# Show all resources created
terraform output -json

# Check via Azure CLI
az resource list -g rg-python-redis-dev --output table

# Check VM status
az vm get-instance-view -g rg-python-redis-dev -n vm-python-redis-app --query "instanceView.statuses"
```

### View Application Logs

From VM (via RDP):

```powershell
# Check if app is running
Get-Process python

# Check Redis service
Get-Service Redis

# View app startup task
Get-ScheduledTask -TaskName "StartPythonApp" | Select-Object -Property TaskName, State

# Manual test
C:\Python311\python.exe C:\app\app.py
```

### Stop or Delete Resources

```powershell
# Stop VM (saves money, keeps resources)
az vm stop -g rg-python-redis-dev -n vm-python-redis-app

# Start VM
az vm start -g rg-python-redis-dev -n vm-python-redis-app

# Delete everything (CAUTION!)
cd terraform
terraform destroy
# Answer: yes (when prompted)
```

## 📊 What Happens During Deployment

1. **Terraform Init** (1 min)
   - Downloads Azure provider
   - Creates state file
   - Validates configuration

2. **Resource Creation** (3-5 min)
   - Resource group, VNet, security rules
   - VM and storage account
   - Network interfaces

3. **VM Startup** (2-3 min)
   - Windows boots
   - VM extensions start

4. **Configuration (DSC)** (2-5 min)
   - Custom script extension runs
   - Python 3.11 installed
   - Redis installed and configured
   - App files deployed
   - Services start

**Total: 8-15 minutes**

## 🔐 Security Notes

### Current Setup (Development)
- ✓ Private network (no internet exposure)
- ✓ Internal-only traffic allowed
- ⚠ Weak Windows password (change it!)
- ⚠ No encryption at rest
- ⚠ No VPN/Bastion for RDP access

### Production Improvements
- [ ] Use Azure Key Vault for passwords
- [ ] Enable Azure Disk Encryption
- [ ] Add Azure Bastion for secure RDP
- [ ] Configure TLS/SSL certificates
- [ ] Set up Network Watcher monitoring
- [ ] Enable Azure Security Center
- [ ] Implement backup policies

## 🐛 Troubleshooting

### "Subscription ID not found"
```powershell
az account show --query "id" -o tsv
# Copy this ID to terraform.tfvars
```

### "Terraform locked"
```powershell
# Running terraform elsewhere? Wait...
# Or force unlock (careful!):
terraform force-unlock <LOCK_ID>
```

### "VM not responding to RDP"
- Wait 10 more minutes for DSC to complete
- Check Azure Portal > VM > Extensions
- Check Windows Event Viewer (RDP into bastion VM first)

### "App not accessible"
```powershell
# From VM via RDP:
Get-Process python                              # Check if running
redis-cli ping                                  # Check Redis
curl http://localhost:8000                      # Test app locally
```

### "DSC failed to apply"
Check VM in Azure Portal:
1. Extensions > DSC > Click for details
2. Look for error messages
3. View C:\Logs\ directory on VM

## 📚 Learning Resources

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure DSC Documentation](https://learn.microsoft.com/en-us/azure/automation/extension-based-dsc-overview)
- [PowerShell DSC](https://learn.microsoft.com/en-us/powershell/scripting/dsc/overview)
- [Terraform Best Practices](https://learn.hashicorp.com/tutorials/terraform/best-practices)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/architecture/framework/)

## 🎯 Next Steps

### Enhance Your Setup

1. **Add Monitoring**
   ```hcl
   resource "azurerm_monitor_diagnostic_setting" "vm" {
     # Add Azure Monitor
   }
   ```

2. **Enable Backup**
   ```hcl
   resource "azurerm_backup_policy_vm" "main" {
     # Add backup policy
   }
   ```

3. **Scale Out**
   - Use VM Scale Sets
   - Add Load Balancer
   - Deploy multiple instances

4. **Automate Deployments**
   - Use Azure Pipelines or GitHub Actions
   - Store state in Azure Storage
   - Implement CI/CD

### Convert to Modules

For reusability, convert to Terraform modules:
```
modules/
├── network/
├── vm/
├── security/
└── dsc/
```

## ❓ FAQ

**Q: Why Windows and not Linux?**
A: DSC is Windows-native. For Linux, use Terraform + cloud-init or Ansible.

**Q: Can I use this for production?**
A: Not yet. Add SSL/TLS, monitoring, backup, and security hardening first.

**Q: How much will this cost?**
A: ~$30-50/month for Standard_B1s VM in eastus region.

**Q: Can I change the app port?**
A: Yes, edit `app_port` in terraform.tfvars (update NSG rules too).

**Q: What if deployment fails halfway?**
A: Check DEPLOYMENT.md troubleshooting section. Most issues are fixable with `terraform apply` again.

## 📝 License & Notes

This is a learning project. Modify and use as needed.

**Key Takeaways:**
- ✓ Infrastructure as Code with Terraform
- ✓ Configuration Management with PowerShell DSC
- ✓ Azure resource provisioning
- ✓ Private network deployment
- ✓ Automated application deployment

---

**Need help?**
1. Check [DEPLOYMENT.md](DEPLOYMENT.md) for detailed troubleshooting
2. See [VS_CODE_SETUP.md](VS_CODE_SETUP.md) for IDE integration
3. Run `.\validate-deployment.ps1` to check prerequisites
4. Review logs in Azure Portal under VM > Extensions

**Happy deploying! 🚀**

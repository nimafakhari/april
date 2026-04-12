terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "b1215226-8364-4b26-a877-1ea57b621a68"
  skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.environment}-vnet"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "${var.environment}-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.subnet_address_prefixes
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.environment}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAppPort"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.app_port
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowRedisPort"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = var.redis_port
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
}

# Network Interface
resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Storage Account for DSC artifacts
resource "azurerm_storage_account" "main" {
  name                     = "st${replace(var.environment, "-", "")}${substr(azurerm_resource_group.main.id, -8, -1)}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "main" {
  name                = var.vm_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  size                = var.vm_size
  tags                = var.tags

  admin_username = var.admin_username
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition-core"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

# DSC Extension for VM Configuration
resource "azurerm_virtual_machine_extension" "dsc" {
  name                       = "DSC"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.83"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    WmfVersion      = "latest"
    ModuleVersion   = "2.0"
    ConfigurationFunction = "dsc_config.Main"
    Properties = {
      RegistrationKey = ""
      RegistrationUrl = ""
      RebootNodeIfNeeded = true
      ActionAfterReboot = "ContinueConfiguration"
      AllowModuleOverwrite = true
    }
  })

  protected_settings = jsonencode({
    StorageEndpointId = azurerm_storage_account.main.primary_blob_endpoint
    StorageAccountName = azurerm_storage_account.main.name
    StorageAccountKey = azurerm_storage_account.main.primary_access_key
  })

  depends_on = [azurerm_virtual_machine_extension.custom_script]
}

# Custom Script Extension to upload DSC and copy app files
resource "azurerm_virtual_machine_extension" "custom_script" {
  name                       = "CustomScript"
  virtual_machine_id         = azurerm_windows_virtual_machine.main.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -ExecutionPolicy Unrestricted -File InitSetup.ps1"
  })

  protected_settings = jsonencode({
    storageAccountName = azurerm_storage_account.main.name
    storageAccountKey = azurerm_storage_account.main.primary_access_key
    fileUris = []
  })

  depends_on = [azurerm_windows_virtual_machine.main]
}

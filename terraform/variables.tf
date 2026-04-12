variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
  default     = "rg-python-redis"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
  default     = "vm-python-app"
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for VM"
  type        = string
  sensitive   = true
}

variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for subnet"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "app_port" {
  description = "Port for Python app"
  type        = number
  default     = 8000
}

variable "redis_port" {
  description = "Port for Redis"
  type        = number
  default     = 6379
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    Project     = "PythonRedisApp"
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

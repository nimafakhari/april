variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "prefix" {
  description = "Name prefix for all resources"
  type        = string
  default     = "april"
}

variable "container_app_name" {
  description = "Name of the Container App to monitor"
  type        = string
  default     = "april-app"
}

variable "alert_email" {
  description = "Email address that receives monitoring alerts"
  type        = string
}

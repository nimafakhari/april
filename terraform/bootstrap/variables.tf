variable "github_repo" {
  description = "GitHub repo in OWNER/REPO form, e.g. nimafakhari/april"
  type        = string
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "tfstate_rg_name" {
  type    = string
  default = "tfstate-rg"
}

variable "tfstate_container_name" {
  type    = string
  default = "tfstate"
}

variable "app_name" {
  type    = string
  default = "april-gh-oidc"
}

variable "production_environment" {
  description = "Name of the GitHub environment used by the apply job"
  type        = string
  default     = "production"
}

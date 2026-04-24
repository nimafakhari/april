data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}

# ---------- Remote state storage ----------
resource "random_string" "sa_suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

resource "azurerm_resource_group" "tfstate" {
  name     = var.tfstate_rg_name
  location = var.location
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "apriltfstate${random_string.sa_suffix.result}"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "tfstate" {
  name                  = var.tfstate_container_name
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}

# ---------- AAD app + service principal for GitHub OIDC ----------
resource "azuread_application" "gh" {
  display_name = var.app_name
}

resource "azuread_service_principal" "gh" {
  client_id = azuread_application.gh.client_id
}

resource "azurerm_role_assignment" "gh_contributor" {
  principal_id         = azuread_service_principal.gh.object_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.current.id
}

# ---------- Federated credentials: GitHub -> AAD app ----------
resource "azuread_application_federated_identity_credential" "main" {
  application_id = azuread_application.gh.id
  display_name   = "gh-main"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:ref:refs/heads/main"
}

resource "azuread_application_federated_identity_credential" "pr" {
  application_id = azuread_application.gh.id
  display_name   = "gh-pr"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:pull_request"
}

resource "azuread_application_federated_identity_credential" "env" {
  application_id = azuread_application.gh.id
  display_name   = "gh-env-${var.production_environment}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repo}:environment:${var.production_environment}"
}

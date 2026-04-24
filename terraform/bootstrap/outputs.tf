output "AZURE_CLIENT_ID" {
  value = azuread_application.gh.client_id
}

output "AZURE_TENANT_ID" {
  value = data.azurerm_client_config.current.tenant_id
}

output "AZURE_SUBSCRIPTION_ID" {
  value = data.azurerm_subscription.current.subscription_id
}

output "TFSTATE_RG" {
  value = azurerm_resource_group.tfstate.name
}

output "TFSTATE_SA" {
  value = azurerm_storage_account.tfstate.name
}

output "TFSTATE_CONTAINER" {
  value = azurerm_storage_container.tfstate.name
}

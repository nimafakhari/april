output "resource_group" {
  value = azurerm_resource_group.this.name
}

output "app_url" {
  value = "https://${azurerm_container_app.app.latest_revision_fqdn}"
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}

output "app_insights_connection_string" {
  value     = azurerm_application_insights.this.connection_string
  sensitive = true
}

# ---------- Action group: who gets notified ----------
resource "azurerm_monitor_action_group" "this" {
  name                = "${var.prefix}-ag"
  resource_group_name = azurerm_resource_group.this.name
  short_name          = "aprilag"

  email_receiver {
    name          = "ops"
    email_address = var.alert_email
  }
}

# ---------- Availability: HTTP ping the app ----------
resource "azurerm_application_insights_standard_web_test" "ping" {
  name                    = "${var.prefix}-ping"
  resource_group_name     = azurerm_resource_group.this.name
  location                = azurerm_resource_group.this.location
  application_insights_id = azurerm_application_insights.this.id
  geo_locations           = ["emea-nl-ams-azr", "emea-de-ber-azr", "emea-se-sto-edge"]
  frequency               = 300
  timeout                 = 30
  enabled                 = true

  request {
    url = "https://${azurerm_container_app.app.latest_revision_fqdn}/"
  }

  validation_rules {
    expected_status_code = 200
    ssl_check_enabled    = true
  }
}

resource "azurerm_monitor_metric_alert" "availability" {
  name                = "${var.prefix}-alert-availability"
  resource_group_name = azurerm_resource_group.this.name
  scopes = [
    azurerm_application_insights.this.id,
    azurerm_application_insights_standard_web_test.ping.id,
  ]
  description = "App is unreachable"
  severity    = 1
  frequency   = "PT1M"
  window_size = "PT5M"

  application_insights_web_test_location_availability_criteria {
    web_test_id           = azurerm_application_insights_standard_web_test.ping.id
    component_id          = azurerm_application_insights.this.id
    failed_location_count = 2
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------- Container restarts (log query alert) ----------
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "restarts" {
  name                = "${var.prefix}-alert-restarts"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  scopes               = [azurerm_log_analytics_workspace.this.id]
  severity             = 2
  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"

  criteria {
    query                   = <<-KQL
      ContainerAppSystemLogs_CL
      | where ContainerAppName_s == "${var.container_app_name}"
      | where Reason_s in ("ContainerRestarted", "ContainerCrashed", "BackOff")
    KQL
    operator                = "GreaterThan"
    threshold               = 0
    time_aggregation_method = "Count"
  }

  action {
    action_groups = [azurerm_monitor_action_group.this.id]
  }
}

# ---------- CPU usage alert ----------
resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "${var.prefix}-alert-cpu"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_container_app.app.id]
  description         = "Container CPU usage > 80%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "UsageNanoCores"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 400000000 # 0.4 vCPU of 0.5 = 80%
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------- Memory usage alert ----------
resource "azurerm_monitor_metric_alert" "memory" {
  name                = "${var.prefix}-alert-memory"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_container_app.app.id]
  description         = "Container memory usage > 80%"
  severity            = 3
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "WorkingSetBytes"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 858993459 # ~0.8 GiB of 1 GiB
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

# ---------- Replica count = 0 (app is down) ----------
resource "azurerm_monitor_metric_alert" "replicas" {
  name                = "${var.prefix}-alert-replicas"
  resource_group_name = azurerm_resource_group.this.name
  scopes              = [azurerm_container_app.app.id]
  description         = "No running replicas"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.App/containerApps"
    metric_name      = "Replicas"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 1
  }

  action {
    action_group_id = azurerm_monitor_action_group.this.id
  }
}

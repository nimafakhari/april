# Azure monitoring (Terraform)

Deploys the app to **Azure Container Apps** and provisions monitoring:

- Log Analytics workspace + Application Insights
- Action group (email)
- Availability web test + alert
- Container restart/crash alert (KQL log query)
- CPU / memory threshold alerts
- Replica-count = 0 alert (app down)

## Use

```powershell
az login
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars   # edit values
terraform init
terraform plan
terraform apply
```

No GitLab/GitHub pipeline required — Terraform talks to Azure directly using your
`az login` session (or a service principal / `ARM_*` env vars in CI if you want one later).

## Check container status

After apply:

```powershell
az containerapp show       -g april-monitoring-rg -n april-app --query "properties.runningStatus"
az containerapp replica list -g april-monitoring-rg -n april-app -o table
az containerapp logs show  -g april-monitoring-rg -n april-app --follow
```

Or in the portal: **Resource group → april-app → Monitoring → Metrics / Logs / Alerts**.

# Bootstrap (Terraform, no bash)

Creates everything the main pipeline needs:

- Resource group + storage account + container for remote tfstate
- AAD app, service principal, `Contributor` on the subscription
- Federated credentials so GitHub Actions can OIDC-login (main, PR, `production` env)

## Run once (Azure Cloud Shell — Terraform is already installed there)

```bash
cd terraform/bootstrap
cp terraform.tfvars.example terraform.tfvars   # edit github_repo
terraform init
terraform apply
terraform output
```

Copy the six outputs into GitHub: **Settings → Secrets and variables → Actions**.

Then in **Settings → Environments**, create `production` and add yourself as a required reviewer.

State is local on purpose (this module exists *to create* the remote state). Don't commit `terraform.tfstate*`.

# Runbook: Debug Terraform Codes

[Back](../README.md)

- [Runbook: Debug Terraform Codes](#runbook-debug-terraform-codes)
  - [Dev Environment](#dev-environment)
  - [Stage Environment](#stage-environment)
  - [Prod Environment](#prod-environment)

---

## Dev Environment

```sh
terraform -chdir=infra/ init -backend-config=backend-dev.config -upgrade
terraform -chdir=infra/ init -backend-config=backend-dev.config --reconfigure
terraform -chdir=infra/ fmt && terraform -chdir=infra/ validate
terraform -chdir=infra/ plan

terraform -chdir=infra/ apply -auto-approve
# terraform -chdir=infra/ destroy -auto-approve

terraform -chdir=infra/ refresh
terraform -chdir=infra/ state list

tflint --chdir=infra --init
tflint --chdir=infra --recursive --format compact
aws eks update-kubeconfig --region ca-central-1 --name gitops-dev

# kubectl apply -f secret.yaml
# kubectl delete application 00-app-of-apps -n argocd
```

---

## Stage Environment

```sh
terraform -chdir=infra/ init -backend-config=backend-stage.config
terraform -chdir=infra/ fmt && terraform -chdir=infra/ validate

terraform -chdir=infra/ apply -auto-approve

aws eks update-kubeconfig --region ca-central-1 --name gitops-stage

terraform -chdir=infra/ destroy -auto-approve
```

---

## Prod Environment

```sh
terraform -chdir=infra/ init -backend-config=backend-prod.config -migrate-state
terraform -chdir=infra/ fmt && terraform -chdir=infra/ validate

terraform -chdir=infra/ apply -auto-approve
terraform -chdir=infra/ destroy -auto-approve
aws eks update-kubeconfig --region ca-central-1 --name gitops-prod

terraform -chdir=infra/ destroy -auto-approve
```

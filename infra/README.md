

```sh
terraform -chdir=infra/dev init -backend-config=backend.config -upgrade
terraform -chdir=infra/dev init -backend-config=backend.config --reconfigure
terraform -chdir=infra/dev fmt && terraform -chdir=infra/dev validate
terraform -chdir=infra/dev plan

terraform -chdir=infra/dev apply -auto-approve

terraform -chdir=infra/dev refresh
terraform -chdir=infra/dev state list

aws eks update-kubeconfig --region ca-central-1 --name gitops-demo-dev

```
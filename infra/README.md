```sh
terraform -chdir=infra/ init -backend-config=backend.config -upgrade
terraform -chdir=infra/ init -backend-config=backend.config --reconfigure
terraform -chdir=infra/ fmt && terraform -chdir=infra/ validate
terraform -chdir=infra/ plan

terraform -chdir=infra/ apply -auto-approve
# terraform -chdir=infra/ destroy -auto-approve

terraform -chdir=infra/ refresh
terraform -chdir=infra/ state list

tflint --init 
tflint --chdir=infra --recursive --format compact
aws eks update-kubeconfig --region ca-central-1 --name gitops-demo-dev


```



```sh
terraform -chdir=infra/dev init -backend-config=backend.config -upgrade
terraform -chdir=infra/dev init -backend-config=backend.config --reconfigure
terraform -chdir=infra/dev fmt && terraform -chdir=infra/dev validate
terraform -chdir=infra/dev plan

terraform -chdir=infra/dev apply -auto-approve
```
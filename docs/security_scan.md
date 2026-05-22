
```sh
# Covers Terraform (infra + modules)
trivy config --severity HIGH,CRITICAL --skip-dirs "**/.terraform" --ignorefile .trivyignore .

# Secrets scan
trivy fs --scanners secret .
```
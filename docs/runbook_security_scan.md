# Runbook: Security Scan

[Back](../README.md)

- [Runbook: Security Scan](#runbook-security-scan)
  - [Securiy Scan](#securiy-scan)

---

## Securiy Scan

```sh
# Covers Terraform (infra + modules)
trivy config --severity HIGH,CRITICAL --skip-dirs "**/.terraform" --ignorefile .trivyignore .

# Secrets scan
trivy fs --scanners secret .
```

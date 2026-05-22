# Project_GitOps_Infra_Repo


## Environment Isolation

| Environment | Branch | GitHub Actions environment | Manifest file | AWS account   |
| ----------- | ------ | -------------------------- | ------------- | ------------- |
| dev         | dev    | dev                        | infra         | dev account   |
| stage       | stage  | stage                      | infra         | stage account |
| prod        | prod   | prod                       | infra         | prod account  |

## action

- Key Actions

| Actions       | Tools                        | Description                               | Custom |
| ------------- | ---------------------------- | ----------------------------------------- | ------ |
| tf-lint-check | tf formate, validate, tflint | terraform lint check                      | \*     |
| security-scan | trivy config, trivy fs       | Security scan terraform config and secret | \*     |
| tf-apply      | tf apply                     | Apply/Destroy infra                       | \*     |
| notify-slack  | slack                        | slack notification                        | \*     |

---

## Pipelines

ci-check
cd-dev (Tf check > tf deploy > notify)
cd-stage(tf check, scan > tf deploy > notify)
release(approval > deploy > notify)

---

### CI Pipeline

- name: 10-ci-check
- Goal: Ensure tf code lint
- concurrency
  - cancel-in-progress=false
- Trigger
  - push
    - branches:
      - "feature-\*"
      - "hotfix-\*"
    - paths:
      - "infra/\*\*"
      - "modules/\*\*"
      - ".github/actions/\*\*"
      - ".github/workflows/\*\*"
  - pull_request:
    - branches:
      - main
    - paths:
      - "infra/\*\*"
      - "modules/\*\*"
      - ".github/actions/\*\*"
      - ".github/workflows/\*\*"
- Key Jobs
  - parallel
    - tf-lint-check
    - security-scan
  - notify-slack [ always ]

---

### CD Pipeline - Dev

- name: 20-cd-dev
- Goal: Deploy dev infra
- Environtmen: dev
- concurrency
  - cancel-in-progress=false
- Trigger
  - push
    - branches:
      - "dev"
    - paths:
      - "infra/\*\*"
      - "modules/\*\*"
- Key Jobs
  - parallel
    - tf-lint-check
    - security-scan
  - tf-apply
  - notify-slack [ always ]

---

### CD Pipeline - Stage

- name: 20-cd-stage
- Goal: Deploy stage infra
- Environtmen: stage
- concurrency
  - cancel-in-progress=false
- Trigger
  - push
    - branches:
      - "stage"
    - paths:
      - "infra/\*\*"
      - "modules/\*\*"
- Key Jobs
  - parallel
    - tf-lint-check
    - security-scan
  - tf-apply
  - notify-slack [ always ]

---

### CD Pipeline - Prod

- name: 30-cd-prod
- Goal: Deploy prod infra
- Environtmen: prod
- concurrency
  - cancel-in-progress=false
- Trigger
  - manuall approval
- Key Jobs
  - parallel
    - tf-lint-check
    - security-scan
  - tf-apply
  - notify-slack [ always ]

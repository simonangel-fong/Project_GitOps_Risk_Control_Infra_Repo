# GitOps Canary Promotion - Infrastructure Repository

**End to End. Auto-Promoted. Canary-Released**

> A production-style GitOps project that separates application, infrastructure, and platform delivery across 3 repositories. <br>
> It uses EKS, ArgoCD, Argo Rollouts, Terraform, and GitHub Actions to automate environment-based deployments, canary promotion, rollback, and post-deployment monitoring and alerting.

![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white&style=plastic) ![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white&style=plastic) ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white&style=plastic) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white&style=plastic) ![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=for-the-badge&logo=prometheus&logoColor=white&style=plastic) ![Slack](https://custom-icon-badges.demolab.com/badge/Slack-4A154B?logo=slack&logoColor=fff) <br>
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white&style=plastic) ![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-FF9900?tyle=for-the-badge&logo=amazoneks&logoColor=white&style=plastic) ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white&style=plastic) ![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white&style=plastic) ![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?logo=springboot&logoColor=fff&style=plastic&style=plastic) ![React](https://img.shields.io/badge/React-%2320232a.svg?logo=react&logoColor=%2361DAFB) <br>

- [GitOps Canary Promotion - Infrastructure Repository](#gitops-canary-promotion---infrastructure-repository)
  - [1. Why This Project Exists](#1-why-this-project-exists)
    - [1.1 Managing App, Infrastructure, and Platform Changes](#11-managing-app-infrastructure-and-platform-changes)
    - [1.2 Releasing Safely Without Business Interruption](#12-releasing-safely-without-business-interruption)
  - [2. Project Architecture](#2-project-architecture)
  - [3. What This Infrastructure Repo Manages](#3-what-this-infrastructure-repo-manages)
    - [3.1 AWS Infrastructure Managed by Terraform](#31-aws-infrastructure-managed-by-terraform)
    - [3.2 Environment Strategy](#32-environment-strategy)
    - [3.3 Infrastructure Security and CI Validation](#33-infrastructure-security-and-ci-validation)
  - [4. Operational Runbooks](#4-operational-runbooks)

---

## 1. Why This Project Exists

### 1.1 Managing App, Infrastructure, and Platform Changes

**Challenge:**

- In enterprise environments, _application code_, _cloud infrastructure_, and _Kubernetes platform configuration_ are often owned by different roles.
- Without clear separation and automated GitOps workflows, delivery can become slow, inconsistent, and difficult to audit.

**Solution:**

- This project uses a `3-repo GitOps strategy` to separate application, infrastructure, and platform responsibilities.
- `CI/CD pipelines` automate validation, image delivery, infrastructure provisioning, and manifest updates, making the delivery process more traceable and repeatable.

---

### 1.2 Releasing Safely Without Business Interruption

**Challenge:**

- Direct production releases increase the risk of downtime, failed deployments, and slow recovery.
- Without a controlled deployment strategy, issues may only be detected after they affect users.

**Solution:**

- This project implements `canary deployment` across isolated `dev`, `stage`, and `prod` environments.
- `Argo Rollouts`, automated analysis, monitoring, and rollback logic help detect issues early, reduce release risk, and protect business continuity.

---

## 2. Project Architecture

- 3-repo GitOps model to separate application delivery, infrastructure provisioning, and platform configuration.

```txt
                                      End Users
                                          |
                                          v
        +---------------------------------------------------------------------+
        |                            EKS Runtime                              |
        |                                                                     |
        |  Applications: Frontend App, Backend App                            |
        |                                                                     |
        |  Platform Add-ons: ESO, Karpenter, ALBC, Envoy, ExternalDNS         |
        |  Delivery & Observability: Argo Rollouts, Prometheus,               |
        |  Alertmanager, Slack Notifications                                  |
        +---------------------------------------------------------------------+
                                          ^
                                          |
                  +-------------------------+------------------------+
                  ^                         ^                        ^
                  |                         |                        |
             Provisioning            Container Image         GitOps Sync / Rollout
                  |                         |                        |
        +---------------------+  +---------------------+   +---------------------+
        |Infrastructure Repo  |  | Application Repo    |   | Platform Repo       |
        |                     |  |                     |   |                     |
        | Terraform           |  |App source code      |   | GitOps manifests    |
        | AWS / EKS clusters  |  | Docker build        |   | App-of-Apps         |
        | ArgoCD install      |  |  CI pipeline        |   | Add-ons / apps      |
        +---------------------+  +---------------------+   +---------------------+
                  ^                        ^                         ^
                  |                        |                         |
             Cloud Engineer             Developer            Platform Engineer

```

| Repository                                                                                                     | Main responsibility                                                                |
| -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Platform Repository](https://github.com/simonangel-fong/Project_GitOps_Canary_Promotion_Platform_Repo.git)    | Add-ons, app manifests, sync waves, canary rollout, monitoring, Slack notification |
| [Application Repository](https://github.com/simonangel-fong/Project_GitOps_Canary_Promotion_App_Repo.git)      | Source code, Docker image build, image push, manifest/image update trigger         |
| [Infrastructure Repository](https://github.com/simonangel-fong/Project_GitOps_Canary_Promotion_Infra_Repo.git) | AWS, EKS clusters, ArgoCD installation, networking foundation                      |

---

## 3. What This Infrastructure Repo Manages

This `Infrastructure Repository` provides the foundational AWS infrastructure for the project, including the `VPC`, `EKS cluster`, `ArgoCD` installation, and initial GitOps bootstrap before application workloads are deployed.

It manages:

- AWS networking foundation through VPC
- Kubernetes runtime through EKS
- EKS managed node groups
- ArgoCD installation on EKS
- App-of-Apps bootstrap for GitOps delivery
- IAM roles and secrets required by platform add-ons such as ESO, ALBC, and ArgoCD

The repository is organized around Terraform ownership, environment separation, and reusable automation:

```text
.
├── .github/
│   ├── actions/            # Reusable GitHub Actions
│   └── workflows/          # Infrastructure CI/CD pipelines
├── infra/                  # Environment-specific Terraform configurations
├── modules/                # Reusable Terraform modules
│   ├── vpc/                # AWS networking foundation
│   ├── eks/                # EKS control plane
│   ├── eks_node_group/     # EKS managed node groups
│   ├── eks_argocd/         # ArgoCD installation and bootstrap
├── docs/                   # Runbooks and supporting documentation
├── .trivyignore.yaml       # Trivy ignore rules
└── README.md
```

---

### 3.1 AWS Infrastructure Managed by Terraform

- `Infrastructure as Code` allows cloud resources to be defined, reviewed, versioned, and provisioned consistently through code; `Terraform` makes this process repeatable across multiple environments.
- `Terraform modules` **package** related resources into reusable building blocks, helping reduce duplication and keep the `dev`, `stage`, and `prod` infrastructure **consistent**.

| Module           | Purpose                                                                   |
| ---------------- | ------------------------------------------------------------------------- |
| `vpc`            | Provisions the AWS networking foundation.                                 |
| `eks`            | Provisions the EKS control plane and core cluster configuration.          |
| `eks_node_group` | Provisions EKS managed node groups used to run Kubernetes workloads.      |
| `eks_argocd`     | Installs ArgoCD on EKS and bootstraps the GitOps App-of-Apps entry point. |

---

### 3.2 Environment Strategy

- This project separates `dev`, `stage`, and `prod` to support progressive infrastructure delivery, environment isolation, and safer production changes.
- Each environment is protected by a dedicated `Git branch` and `EKS cluster`, ensuring infrastructure changes can move through the delivery flow with lower risk.

| Env     | Branch  | Cluster        | Purpose                                            |
| ------- | ------- | -------------- | -------------------------------------------------- |
| `dev`   | `dev`   | `gitops-dev`   | Safe space for development and early validation    |
| `stage` | `stage` | `gitops-stage` | Production-like environment for release validation |
| `prod`  | `prod`  | `gitops-prod`  | Live environment for end users                     |

---

### 3.3 Infrastructure Security and CI Validation

This repository validates Terraform code, scans for secrets, and uses controlled AWS access before infrastructure changes are promoted.

| Security Practice                          | Purpose                                                                                       |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `trivy config`                             | Detects Terraform misconfigurations and insecure defaults before provisioning.                |
| `trivy fs --scanners secret .`             | Detects exposed secrets, credentials, and tokens in the repository.                           |
| `GitHub Actions OIDC + AWS IAM Role`       | Uses short-lived AWS credentials instead of long-lived access keys.                           |
| `ArgoCD Secrets + AWS SSM Parameter Store` | Externalizes sensitive values and injects them into EKS through controlled secret management. |

---

## 4. Operational Runbooks

- [Runbook: CI/CD Pipeline](docs/runbook_cicd.md):
  - Debug infrastructure CI/CD pipeline failures.
- [Runbook: Debug Terraform Codes](docs/runbook_debug_infra.md):
  - Debug Terraform code, modules, plans, and provisioning issues.
- [Runbook: Security Scan](docs/runbook_security_scan.md):
  - Run and troubleshoot Terraform and secret security scans.
- [Runbook: Debug ArgoCD](docs/runbook_debug_argocd.md):
  - Debug ArgoCD installation, sync status, and GitOps bootstrap issues.

# GitOps Risk Control - Infrastructure Repository

**Validate Early. Release Gradually. Detect Fast.**

> A production-style GitOps project that reduces release risk across the delivery lifecycle.
> It validates changes through `multi-repo` and `multi-environment promotion`, releases gradually with `canary deployment`, and detects post-release issues through **monitoring** and **alerting**.

![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white&style=plastic) ![Argo CD](https://img.shields.io/badge/Argo%20CD-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![Argo Rollouts](https://img.shields.io/badge/Argo%20Rollouts-EF7B4D?style=for-the-badge&logo=argo&logoColor=white&style=plastic) ![GitHub Actions](https://img.shields.io/badge/GitHub%20Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white&style=plastic) ![Prometheus](https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white&style=plastic) ![Grafana](https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white&style=plastic) ![Alertmanager](https://img.shields.io/badge/Alertmanager-E6522C?style=for-the-badge&logo=prometheus&logoColor=white&style=plastic) ![Slack](https://custom-icon-badges.demolab.com/badge/Slack-4A154B?logo=slack&logoColor=fff) <br>
![AWS](https://img.shields.io/badge/AWS-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white&style=plastic) ![Amazon EKS](https://img.shields.io/badge/Amazon%20EKS-FF9900?style=for-the-badge&logo=amazoneks&logoColor=white&style=plastic) ![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white&style=plastic) ![Kustomize](https://img.shields.io/badge/Kustomize-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white&style=plastic) ![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white&style=plastic) ![Spring Boot](https://img.shields.io/badge/Spring%20Boot-6DB33F?logo=springboot&logoColor=fff&style=plastic) ![React](https://img.shields.io/badge/React-%2320232a.svg?logo=react&logoColor=%2361DAFB&style=plastic) <br>

- [GitOps Risk Control - Infrastructure Repository](#gitops-risk-control---infrastructure-repository)
  - [Challenge and Solution](#challenge-and-solution)
  - [What This Infrastructure Repo Manages](#what-this-infrastructure-repo-manages)
    - [AWS Infrastructure Managed by Terraform](#aws-infrastructure-managed-by-terraform)
    - [Environment Strategy](#environment-strategy)
    - [Infrastructure Security and CI Validation](#infrastructure-security-and-ci-validation)

---

## Challenge and Solution

**Challenge:**

Every production release carries the risk of introducing **bugs that affect users and disrupt business operations**. <br>
How can changes be **validated early**, **released gradually**, and **monitored continuously** to reduce business impact?

**Solution:**

This project implements a **GitOps-based release risk control workflow** across three phases:

| Phase        | Project Approach                                                                                           | Goal                                              |
| ------------ | ---------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| Pre-release  | Separate responsibilities with dedicated repositories and isolated `dev`, `stage`, and `prod` environments | Catch issues early before they reach production   |
| Release      | Use `canary deployment` and automated rollout control                                                      | Limit the impact of failed releases               |
| Post-release | Monitor system health and trigger alerts after deployment                                                  | Detect incidents quickly and reduce recovery time |

---

## What This Infrastructure Repo Manages

This `Infrastructure Repository` provides the foundational AWS infrastructure for the project, including the `VPC`, `EKS cluster`, `ArgoCD` installation, and initial GitOps bootstrap before application workloads are deployed.

It manages:

- AWS networking foundation through VPC
- Kubernetes runtime through EKS
- EKS managed node groups
- ArgoCD installation on EKS
- App-of-Apps bootstrap for GitOps delivery
- IAM roles and secrets required by platform add-ons such as ESO, ALBC, and ArgoCD

![tf-env](./docs/assets/infra-diagram.png)

---

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

### AWS Infrastructure Managed by Terraform

- `Infrastructure as Code` allows cloud resources to be defined, reviewed, versioned, and provisioned consistently through code; `Terraform` makes this process repeatable across multiple environments.
- `Terraform modules` **package** related resources into reusable building blocks, helping reduce duplication and keep the `dev`, `stage`, and `prod` infrastructure **consistent**.

| Module           | Purpose                                                                   |
| ---------------- | ------------------------------------------------------------------------- |
| `vpc`            | Provisions the AWS networking foundation.                                 |
| `eks`            | Provisions the EKS control plane and core cluster configuration.          |
| `eks_node_group` | Provisions EKS managed node groups used to run Kubernetes workloads.      |
| `eks_argocd`     | Installs ArgoCD on EKS and bootstraps the GitOps App-of-Apps entry point. |

---

### Environment Strategy

- This project separates `dev`, `stage`, and `prod` to support progressive infrastructure delivery, environment isolation, and safer production changes.
- Each environment is protected by a dedicated `Git branch` and `EKS cluster`, ensuring infrastructure changes can move through the delivery flow with lower risk.

| Env     | Branch  | Cluster        | Purpose                                            |
| ------- | ------- | -------------- | -------------------------------------------------- |
| `dev`   | `dev`   | `gitops-dev`   | Safe space for development and early validation    |
| `stage` | `stage` | `gitops-stage` | Production-like environment for release validation |
| `prod`  | `prod`  | `gitops-prod`  | Live environment for end users                     |

---

### Infrastructure Security and CI Validation

This repository validates Terraform code, scans for secrets, and uses controlled AWS access before infrastructure changes are promoted.

| Security Practice                          | Purpose                                                                                       |
| ------------------------------------------ | --------------------------------------------------------------------------------------------- |
| `trivy config`                             | Detects Terraform misconfigurations and insecure defaults before provisioning.                |
| `trivy fs --scanners secret .`             | Detects exposed secrets, credentials, and tokens in the repository.                           |
| `GitHub Actions OIDC + AWS IAM Role`       | Uses short-lived AWS credentials instead of long-lived access keys.                           |
| `ArgoCD Secrets + AWS SSM Parameter Store` | Externalizes sensitive values and injects them into EKS through controlled secret management. |

---

- **Associated Repositories**
  - [Platform Repository](https://github.com/simonangel-fong/Project_GitOps_Risk_Control_Platform_Repo.git)
  - [Application Repository](https://github.com/simonangel-fong/Project_GitOps_Risk_Control_App_Repo.git)
  - [Infrastructure Repository](https://github.com/simonangel-fong/Project_GitOps_Risk_Control_Infra_Repo.git)

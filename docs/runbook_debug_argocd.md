# Runbook: Debug Terraform Codes

[Back](../README.md)

- [Runbook: Debug Terraform Codes](#runbook-debug-terraform-codes)
  - [Terraform Module](#terraform-module)
  - [What this module does](#what-this-module-does)
  - [Requirements](#requirements)
  - [Usage](#usage)
    - [Minimal example](#minimal-example)
    - [Full example with provider wiring](#full-example-with-provider-wiring)
    - [Install Argo CD only (skip the root Application)](#install-argo-cd-only-skip-the-root-application)
    - [Notifications](#notifications)
  - [Templates](#templates)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
  - [Accessing the Argo CD UI](#accessing-the-argo-cd-ui)
  - [Notes](#notes)

---

## Terraform Module

Terraform module that installs [Argo CD](https://argo-cd.readthedocs.io/) onto an existing EKS cluster via the official Helm chart and (optionally) bootstraps a **root "app-of-apps"** `Application` that points at your GitOps config repo.

This module follows upstream ArgoCD conventions and hardcodes the names you'd otherwise be tempted to make configurable:

| What             | Value            |
| ---------------- | ---------------- |
| Namespace        | `argocd`         |
| Helm release     | `argocd`         |
| Root Application | `00-app-of-apps` |

The Argo `AppProject` is named after `var.project_name` and scopes the root app-of-apps tree to your GitOps repo. If you need different namespace/release/root-app names, fork the module — don't bolt on parameters.

## What this module does

1. Installs the `argo-cd` Helm chart from `https://argoproj.github.io/argo-helm` into the `argocd` namespace (created if missing).
2. Renders [`manifests/values.tftpl`](./manifests/values.tftpl) (server type, notifications toggle) and merges your optional `var.values` YAML on top.
3. Applies an `AppProject` named `var.project_name`, scoped to `var.gitops_repo_url` and the in-cluster API. Every Application under the root app-of-apps tree belongs to this project.
4. If `enable_root_app = true`, applies a single `Application` (assigned to `var.project_name`) that tells Argo CD to sync `gitops_repo_path` from `gitops_repo_url` — the entry point of the app-of-apps pattern.
5. If `enable_notifications = true`, flips on the chart's notifications controller. **Notifier configuration (`service.slack`, templates, triggers, subscriptions) and the `argocd-notifications-secret` are managed in-cluster** (typically ESO + the GitOps repo), not by this module.

## Requirements

| Name                  | Version |
| --------------------- | ------- |
| terraform             | >= 1.10 |
| helm                  | >= 2.13 |
| kubectl (gavinbunney) | >= 1.14 |

The caller must configure the `helm` and `kubectl` providers to point at the target EKS cluster (see example below).

## Usage

### Minimal example

```hcl
module "eks_argocd" {
  source = "../../modules/eks_argocd"

  project_name    = "gitops"
  gitops_repo_url = "https://github.com/your-org/your-gitops-config-repo.git"

  depends_on = [module.eks_node_group]
}
```

### Full example with provider wiring

```hcl
data "aws_eks_cluster" "this" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

provider "kubectl" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

module "eks_argocd" {
  source = "../../modules/eks_argocd"

  chart_version = "9.5.14"

  # Extra Helm values merged on top of values.tftpl
  values = yamlencode({
    server = {
      service = { type = "LoadBalancer" }
    }
  })

  # AppProject (scopes the root app-of-apps tree)
  project_name = "gitops"

  # Root app-of-apps
  enable_root_app      = true
  gitops_repo_url      = "https://github.com/your-org/your-gitops-config-repo.git"
  gitops_repo_revision = "main"
  gitops_repo_path     = "bootstrap"

  # Turns on the notifications controller; notifier config lives in-cluster.
  enable_notifications = true

  depends_on = [module.eks_node_group]
}
```

### Install Argo CD only (skip the root Application)

```hcl
module "eks_argocd" {
  source = "../../modules/eks_argocd"

  project_name    = "gitops"
  enable_root_app = false
  gitops_repo_url = "https://github.com/your-org/your-gitops-config-repo.git"
}
```

> The `AppProject` is always created (it's cheap and needed as soon as you flip `enable_root_app = true`). `gitops_repo_url` is still required because the project scopes `sourceRepos` to it.

### Notifications

This module only flips the controller on. Everything else is delivered through ArgoCD itself from your GitOps repo:

- `argocd-notifications-secret` — created by an `ExternalSecret` that pulls the Slack bot token (e.g. from SSM/Secrets Manager) into the `argocd` namespace under the key `slack-token`.
- `argocd-notifications-cm` — declares `service.slack`, templates, triggers, and any cluster-wide subscriptions.
- Per-`Application` annotations — opt individual apps into channels:

```yaml
metadata:
  annotations:
    notifications.argoproj.io/subscribe.on-sync-failed.slack: my-channel
```

Because the Slack token never enters Terraform, it never lands in TF state.

## Templates

The YAML payloads this module produces live as readable templates:

- [`manifests/values.tftpl`](./manifests/values.tftpl) — base Helm values for the chart. Rendered with `enable_notifications`. Your `var.values` is appended afterwards, so later values win in the Helm merge.
- [`manifests/project.tftpl`](./manifests/project.tftpl) — the `AppProject`. Rendered with `namespace`, `project_name`, `gitops_repo_url`. Tighten `sourceRepos` / `destinations` / `*Whitelist` here if you need stricter RBAC.
- [`manifests/app-of-apps.tftpl`](./manifests/app-of-apps.tftpl) — the root `Application` manifest. Rendered with `namespace`, `root_app_name`, `root_app_project`, `gitops_repo_url`, `gitops_repo_revision`, `gitops_repo_path`.

## Inputs

| Name                   | Description                                                                            | Type     | Default       | Required |
| ---------------------- | -------------------------------------------------------------------------------------- | -------- | ------------- | :------: |
| `chart_version`        | Version of the [argo-cd Helm chart](https://artifacthub.io/packages/helm/argo/argo-cd) | `string` | `"9.5.14"`    |    no    |
| `values`               | Additional Helm values YAML, merged on top of `values.tftpl`                           | `string` | `""`          |    no    |
| `project_name`         | Name of the Argo `AppProject` scoping the root app-of-apps tree                        | `string` | n/a           | **yes**  |
| `enable_root_app`      | Whether to create the root app-of-apps `Application`                                   | `bool`   | `true`        |    no    |
| `gitops_repo_url`      | Git URL of the GitOps config repo Argo CD will sync from                               | `string` | n/a           | **yes**  |
| `gitops_repo_revision` | Git revision (branch, tag, or commit) tracked by the root app                          | `string` | `"HEAD"`      |    no    |
| `gitops_repo_path`     | Path inside the GitOps repo with the root app-of-apps manifests                        | `string` | `"bootstrap"` |    no    |
| `enable_notifications` | Enable the Argo CD notifications controller (notifier config managed in-cluster)       | `bool`   | `false`       |    no    |

## Outputs

| Name                    | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `namespace`             | Namespace where Argo CD was installed (always `argocd`) |
| `release_name`          | Helm release name (always `argocd`)                     |
| `chart_version`         | Installed chart version                                 |
| `root_app_name`         | Name of the root `Application`, or `null` when disabled |
| `notifications_enabled` | Whether the Argo CD notifications controller is enabled |

## Accessing the Argo CD UI

After apply, port-forward the server (default service type is `ClusterIP`):

```sh
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Get the initial admin password:

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Then open <https://localhost:8080> and log in as `admin`.

## Notes

- The Helm release is created with `wait = true` and a 600 s `timeout` because Argo CD CRDs are large and slow to install.
- The root `Application` has `automated.prune = true` and `selfHeal = true`; anything you remove from the GitOps repo will be pruned from the cluster.
- Always set `depends_on = [module.eks_node_group]` (or whatever creates worker nodes) so the chart has somewhere to schedule pods.

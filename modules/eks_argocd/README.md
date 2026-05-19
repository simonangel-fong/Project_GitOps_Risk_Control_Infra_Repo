# eks_argocd

Terraform module that installs [Argo CD](https://argo-cd.readthedocs.io/) onto an existing EKS cluster via the official Helm chart and (optionally) bootstraps a **root "app-of-apps"** `Application` that points at your GitOps config repo.

## What this module does

1. Installs the `argo-cd` Helm chart from `https://argoproj.github.io/argo-helm` into the chosen namespace (created if missing).
2. Applies a default `values.yaml` (ClusterIP server, empty global domain) merged with any extra values you pass.
3. If `enable_root_app = true`, applies a single `Application` manifest that tells Argo CD to sync `gitops_repo_path` from `gitops_repo_url` — the entry point of the app-of-apps pattern.

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

  namespace      = "argocd"
  release_name   = "argocd"
  chart_version  = "9.5.14"

  # Extra Helm values merged on top of module defaults
  values = yamlencode({
    server = {
      service = { type = "LoadBalancer" }
    }
  })

  # Root app-of-apps
  enable_root_app      = true
  gitops_repo_url      = "https://github.com/your-org/your-gitops-config-repo.git"
  gitops_repo_revision = "main"
  gitops_repo_path     = "bootstrap"
  root_app_name        = "root"
  root_app_project     = "default"

  depends_on = [module.eks_node_group]
}
```

### Install Argo CD only (skip the root Application)

```hcl
module "eks_argocd" {
  source = "../../modules/eks_argocd"

  enable_root_app = false
  gitops_repo_url = "" # still required by the variable; ignored when disabled
}
```

## Inputs

| Name                   | Description                                                                            | Type     | Default       | Required |
| ---------------------- | -------------------------------------------------------------------------------------- | -------- | ------------- | :------: |
| `namespace`            | Namespace where Argo CD is installed                                                   | `string` | `"argocd"`    |    no    |
| `release_name`         | Helm release name for argo-cd                                                          | `string` | `"argocd"`    |    no    |
| `chart_version`        | Version of the [argo-cd Helm chart](https://artifacthub.io/packages/helm/argo/argo-cd) | `string` | `"9.5.14"`    |    no    |
| `values`               | Additional Helm values YAML, merged on top of module defaults                          | `string` | `""`          |    no    |
| `enable_root_app`      | Whether to create the root app-of-apps `Application`                                   | `bool`   | `true`        |    no    |
| `gitops_repo_url`      | Git URL of the GitOps config repo Argo CD will sync from                               | `string` | n/a           | **yes**  |
| `gitops_repo_revision` | Git revision (branch, tag, or commit) tracked by the root app                          | `string` | `"HEAD"`      |    no    |
| `gitops_repo_path`     | Path inside the GitOps repo with the root app-of-apps manifests                        | `string` | `"bootstrap"` |    no    |
| `root_app_name`        | Name of the root Argo `Application`                                                    | `string` | `"root"`      |    no    |
| `root_app_project`     | Argo CD project the root application belongs to                                        | `string` | `"default"`   |    no    |

## Outputs

| Name            | Description                                             |
| --------------- | ------------------------------------------------------- |
| `namespace`     | Namespace where Argo CD was installed                   |
| `release_name`  | Helm release name                                       |
| `chart_version` | Installed chart version                                 |
| `root_app_name` | Name of the root `Application`, or `null` when disabled |

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

---

## Connetion

```sh
kubectl port-forward svc/argocd-server 8000:80 -n argocd

k get secret argocd-initial-admin-secret -n argocd -o yaml

echo NXZtamphSUZIcVRXTWFvWA== | base64 -d
```
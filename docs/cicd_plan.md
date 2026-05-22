# CI/CD Plan — Project_GitOps_Infra_Repo

This document refines the pipeline design sketched in the root [README.md](../README.md). It defines the branching model, workflows, composite actions, environments, secrets, and guardrails the repo should converge on.

---

## 1. Goals & Non-Goals

**Goals**

- Every change to `infra/**` or `modules/**` is linted, scanned, planned, and applied through GitHub Actions — never from a laptop.
- Each AWS environment (dev / stage / prod) maps 1:1 to a git branch, a GitHub Actions environment, an AWS account, and an S3 state key.
- Production changes always require human approval and a reviewable plan artifact.
- All AWS auth is short-lived OIDC; no long-lived access keys in GitHub.
- Slack gets a result notification for every workflow run.

**Non-Goals (out of scope here)**

- Application CD for workloads deployed onto EKS (Argo CD handles that — see [modules/eks_argocd/](../modules/eks_argocd/)).
- Multi-region rollout strategies.
- Cost-policy enforcement (Infracost) — listed as a future enhancement.

---

## 2. Branching & Environment Model

There is **one** Terraform root module ([infra/](../infra/)) shared by every environment. Environments are differentiated only by the inputs (variables + backend config) injected at `init` / `plan` time — never by duplicating `.tf` code.

| Environment | Branch  | GH Actions Environment | AWS account | TF state key                        |
| ----------- | ------- | ---------------------- | ----------- | ----------------------------------- |
| dev         | `dev`   | `dev`                  | dev         | `<project>/dev/terraform.tfstate`   |
| stage       | `stage` | `stage`                | stage       | `<project>/stage/terraform.tfstate` |
| prod        | `prod`  | `prod`                 | prod        | `<project>/prod/terraform.tfstate`  |

All per-env inputs (variables and backend config) come from **GitHub environment secrets and variables** at runtime. Nothing per-env is committed to the repo. See §6 for the full secret/variable list.

**Repo layout:**

```
infra/                     ← single Terraform root, parameterized by var.env
├── 01_variables.tf
├── 02_local.tf
├── 03_provider.tf         ← empty backend {}; bucket/key/region injected at init
├── 04_outputs.tf
├── 05_main.tf
├── 06_albc.tf
├── 07_eso.tf
├── .tflint.hcl
├── .terraform.lock.hcl
├── README.md
└── manifests/             ← Kubernetes manifests (sibling, not Terraform)
modules/                   ← reusable child modules
├── vpc/
├── eks/
├── eks_node_group/
└── eks_argocd/
```

**Flow:** `feature-*` / `hotfix-*` → PR into `dev` → merge → promote `dev` → `stage` → `prod` via fast-forward merges or release PRs.

> The current README maps PRs to `main`, but only `dev`/`stage`/`prod` are deployable. Drop `main` from the model and treat `dev` as the integration trunk. Update [10-ci-check.yml](../.github/workflows/10-ci-check.yml) `pull_request.branches` to `[dev, stage, prod]`.

---

## 3. Pipeline Inventory

| #   | Workflow file         | Trigger                                    | Purpose                                              |
| --- | --------------------- | ------------------------------------------ | ---------------------------------------------------- |
| 1   | `10-ci-check.yml`     | push `feature-*`/`hotfix-*`, PR to env br. | Lint + scan only. No AWS auth. No state access.      |
| 2   | `20-cd-dev.yml`       | push to `dev`                              | Lint + scan + plan + apply in dev account.           |
| 3   | `21-cd-stage.yml`     | push to `stage`                            | Lint + scan + plan + apply in stage account.         |
| 4   | `30-cd-prod.yml`      | push to `prod` **or** `workflow_dispatch`  | Lint + scan + plan → **manual approval** → apply.    |
| 5   | `40-drift-detect.yml` | schedule (daily 06:00 UTC) + manual        | `terraform plan` per env, post diff to Slack if ≠ 0. |
| 6   | `90-tf-destroy.yml`   | `workflow_dispatch` only (env input)       | Guarded destroy path; requires typed confirmation.   |

All workflows share the same composite actions in [.github/actions/](../.github/actions/).

---

## 4. Composite Actions (reuse layer)

| Action                                                       | Responsibility                                                                                    | Notes                                               |
| ------------------------------------------------------------ | ------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| [tf-lint-check](../.github/actions/tf-lint-check/action.yml) | `terraform fmt -check`, `init -backend=false`, `validate`, `tflint --recursive`                   | No AWS auth needed.                                 |
| [security-scan](../.github/actions/security-scan/action.yml) | Single Trivy invocation (`config` for IaC, `secret` for repo). Uploads SARIF.                     | Called twice per CI run with different `scan-mode`. |
| [tf-apply](../.github/actions/tf-apply/action.yaml)          | OIDC auth → `init` (S3 backend) → `plan` → upload plan artifact → `apply`. Supports `is_destroy`. | Plan artifact retained 3 days.                      |
| [notify-slack](../.github/actions/notify-slack/action.yml)   | Aggregates `needs` context → posts colored summary to webhook.                                    | Always-run job at end of every workflow.            |

**Gaps to fix in [tf-apply](../.github/actions/tf-apply/action.yaml):**

1. **Default `tf_dir` to `infra`.** Keep it as an input for flexibility, but the single-root layout means it's `infra` in every caller.
2. **Keep inline `-backend-config=` flags** (already correct in [tf-apply](../.github/actions/tf-apply/action.yaml#L78-L83)). Bucket / region / key come from GH environment variables — no committed `.backend.hcl` file needed.
3. **No `tfvars_file` input needed.** Variables come from `TF_VAR_*` env vars sourced from GH environment secrets/variables; Terraform picks them up automatically.
4. **Add `mode: plan|apply` input** so prod can split plan and apply across an approval gate (plan job uploads `tfplan` artifact → approval → apply job downloads and runs `terraform apply tfplan`). Dev/stage call it once with the default (plan-and-apply).

---

## 5. Workflow Specs

### 5.1 `10-ci-check.yml` — CI (no AWS, no state)

- **Concurrency:** `group: ci-${{ github.ref }}`, `cancel-in-progress: true` (already set — keep).
- **Triggers**
  - `push`: `feature-*`, `hotfix-*` on the same path filter (`infra/**`, `modules/**`, `.github/actions/**`, `.github/workflows/**`).
  - `pull_request` to `dev`, `stage`, `prod` (same path filter).
  - `workflow_dispatch` for manual re-runs.
- **Jobs (parallel)**
  1. `tf-lint-check` — runs once against [infra/](../infra/) (one root → one lint pass). Use `terraform validate` without env-specific values; the root must be valid for any env.
  2. `tf-sec-scan` — Trivy `config` over `infra/` and `modules/`, skip `**/.terraform`, `**/terraform-aws-modules`.
  3. `secret-scan` — Trivy `fs --scanners secret` over repo root.
- **Final job:** `notify-slack` with `if: always()`, `needs: [tf-lint-check, tf-sec-scan, secret-scan]`.
- **Permissions:** `id-token: none`, `contents: read`, `pull-requests: write` (for plan comments — see §7), `security-events: write` (for SARIF).

### 5.2 `20-cd-dev.yml` / `21-cd-stage.yml`

- **Concurrency:** `group: cd-${{ github.workflow }}`, `cancel-in-progress: false` — never cancel a half-applied state.
- **Trigger:** `push` to the env branch + `workflow_dispatch`.
- **Environment:** `dev` / `stage` (GH environment).
- **Jobs (sequential)**
  1. `validate` — parallel matrix: `tf-lint-check`, `tf-sec-scan`, `secret-scan` (reuse CI jobs via reusable workflow or copy-paste). Fail fast.
  2. `apply` — `needs: validate`. Uses [tf-apply](../.github/actions/tf-apply/action.yaml) with `tf_env: dev|stage`, `tf_dir: infra`, and the GH environment supplies `AWS_CICD_ROLE_ARN`, `AWS_REGION`, `AWS_BACKEND_BUCKET`, and `TF_VAR_*` secrets (see §6).
  3. `notify-slack` — `if: always()`.
- **Permissions:** `id-token: write`, `contents: read`.

### 5.3 `30-cd-prod.yml` — production with approval gate

- **Trigger:** `push` to `prod` **or** `workflow_dispatch`.
- **Concurrency:** `group: cd-prod`, `cancel-in-progress: false`.
- **Jobs**
  1. `validate` — same as above.
  2. `plan` — `needs: validate`. Uses `tf-apply` with `mode: plan`; uploads `tfplan` artifact.
  3. `approval-gate` — `needs: plan`. Environment `prod` with **required reviewers** configured in repo settings. No steps; the environment protection rule supplies the wait.
  4. `apply` — `needs: approval-gate`. Downloads `tfplan` artifact, runs `terraform apply tfplan` (no re-plan, no drift between approval and apply).
  5. `notify-slack` — `if: always()`.

### 5.4 `40-drift-detect.yml`

- `schedule: cron: "0 6 * * *"` + `workflow_dispatch`.
- Matrix per env: run `terraform plan -detailed-exitcode`. Exit 2 = drift → post to Slack with the env name and a link to the run.

### 5.5 `90-tf-destroy.yml`

- `workflow_dispatch` only. Inputs: `environment` (choice), `confirm` (must equal env name).
- Hard fail if `confirm != environment`.
- Uses `tf-apply` with `is_destroy: true`.
- Posts a louder Slack message (different icon/color).

---

## 6. Secrets, Variables, OIDC

All per-env config lives in GitHub environment secrets/variables. No `.tfvars` files, no `.backend.hcl` files committed to the repo.

### Per-environment (configured in GH environment `dev` / `stage` / `prod`)

**Used by [tf-apply](../.github/actions/tf-apply/action.yaml) to talk to AWS and configure the backend:**

| Name                  | Kind     | Purpose                                                       |
| --------------------- | -------- | ------------------------------------------------------------- |
| `AWS_CICD_ROLE_ARN`   | secret   | IAM role assumed via OIDC. Trust policy scoped to repo + env. |
| `AWS_REGION`          | variable | e.g. `ca-central-1`. Also used as `TF_VAR_aws_region`.        |
| `AWS_BACKEND_BUCKET`  | variable | S3 bucket holding state for this env's account.               |
| `PROJECT_NAME`        | variable | State-key prefix, e.g. `gitops-demo`.                         |

**Consumed by Terraform as `TF_VAR_*` (no tfvars file needed — Terraform reads these env vars automatically):**

| Name                          | Kind     | Maps to Terraform variable      |
| ----------------------------- | -------- | ------------------------------- |
| `TF_VAR_env`                  | variable | `var.env` (`dev`/`stage`/`prod`) |
| `TF_VAR_aws_region`           | variable | `var.aws_region`                |
| `TF_VAR_cloudflare_api_key`   | secret   | `var.cloudflare_api_key`        |
| `TF_VAR_slack_bot_token`      | secret   | `var.slack_bot_token` (optional — leave unset to disable ArgoCD Slack notifications) |

### Repo-level

| Name                | Kind   | Notes                                      |
| ------------------- | ------ | ------------------------------------------ |
| `SLACK_WEBHOOK_URL` | secret | Used by [notify-slack](../.github/actions/notify-slack/action.yml). Single channel for now; can split per-env. |

### OIDC trust policy condition (per role)

```
token.actions.githubusercontent.com:sub = repo:<org>/Project_GitOps_Infra_Repo:environment:<dev|stage|prod>
```

This pins each role to its env so a dev workflow cannot assume the prod role even with a misconfigured workflow.

### Local development

Laptop runs are out of scope (see §1 Goals — apply always goes through CI). If a developer ever needs to run `terraform plan` locally for debugging, they create an uncommitted `infra/terraform.tfvars` themselves (the file is gitignored by [./.gitignore](../.gitignore)) and use `export AWS_PROFILE=...` for credentials. No template is committed.

---

## 7. Guardrails

- **PR plan comment** _(future)_: on PR to `dev`/`stage`/`prod`, run `terraform plan -no-color` against the target env's state (read-only role) and post a collapsed diff as a PR comment. Requires a separate `*-read-only` IAM role.
- **Required status checks:** branch protection on `dev`/`stage`/`prod` must require `tf-lint-check`, `tf-sec-scan`, `secret-scan` to pass before merge.
- **Linear history** on `prod`. No force-push, no direct commits (PR only).
- **State locking:** the S3 backend already uses `use_lockfile = true` ([infra/03_provider.tf:31-37](../infra/03_provider.tf#L31-L37)) — the S3-native conditional-write lock, no DynamoDB table needed. Keep it.
- **No `terraform apply -auto-approve` outside CI.** Add a `CONTRIBUTING.md` note.
- **Plan artifact retention:** 3 days (already set). For prod, raise to 14 days for post-mortem traceability.

---

## 8. Open Items / Follow-Ups

**File-structure work (will be executed after plan approval):**

1. Move `infra/root/*` → `infra/` (flatten one level).
2. Delete `infra/envs/` (contents replaced by GH environment secrets/variables).

**Workflow + action updates:**

3. **Update [tf-apply](../.github/actions/tf-apply/action.yaml):** default `tf_dir` to `infra`; add `mode: plan|apply` input for the prod approval gate. Keep the existing inline `-backend-config=` flags.
4. **Update [10-ci-check.yml](../.github/workflows/10-ci-check.yml):** replace `WORKING_DIR: infra/dev` with `infra`; change `pull_request.branches: [main]` to `[dev, stage, prod]`; update `TF_SCAN_DIR` if it still points at `infra/dev`.
5. Add the new `20-cd-dev.yml`, `21-cd-stage.yml`, `30-cd-prod.yml`, `40-drift-detect.yml`, `90-tf-destroy.yml` workflows (none exist yet).

**Operational setup (outside the repo):**

6. **Rotate the Cloudflare API key** that was in `infra/dev/terraform.tfvars` (now in the gitignored, soon-to-be-deleted `infra/envs/dev.tfvars`). Set the new value as `TF_VAR_CLOUDFLARE_API_KEY` in each GH environment.
7. Provision per-env IAM roles with the OIDC trust condition from §6.
8. Configure GH environments `dev`, `stage`, `prod` with the secrets/variables from §6 and required reviewers on `prod`.

**Open questions:**

9. Decide whether `secret-scan` should scan PR diffs only (faster) or full tree (current behavior, more thorough). Recommend: full tree on CI, diff-only on PR.

---

## 9. Diagram

```
feature-*  ──▶ PR ──▶ [10-ci-check]  ──▶ merge to dev
                                             │
                                             ▼
                                       [20-cd-dev] ──▶ dev AWS account
                                             │
                                             ▼ (promote)
                                       [21-cd-stage] ──▶ stage AWS account
                                             │
                                             ▼ (promote)
                                       [30-cd-prod: plan]
                                             │
                                             ▼
                                       [approval gate]
                                             │
                                             ▼
                                       [30-cd-prod: apply] ──▶ prod AWS account

  (daily) [40-drift-detect] ──▶ Slack if any env drifts
```

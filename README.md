# Response Classifier AWS

A machine learning project for response classification, deployed on AWS using **Terraform** for infrastructure provisioning and **AWS CDK** for application-level resources (Lambda functions, API Gateway, monitoring).

---

## Project Structure

```
response-classifier-aws/
│
├── .devcontainer/                # VS Code / GitHub Codespaces dev container
|   ├── bash_profile              # Added aliases, env vars, and functions for the shell
│   ├── devcontainer.json         # Container config, extensions, and VS Code settings
│   ├── Dockerfile                # Python 3.12, Terraform, AWS CDK, AWS CLI
│   └── post-create.sh            # Runs after build — installs deps, aliases, Jupyter kernel
│
├── .github/
│   └── workflows/                # GitHub Actions CI/CD pipelines
│       ├── ci.yml                # Lint, Terraform validate, CDK synth — runs on every PR
│       ├── terraform.yml         # Terraform plan (PR) → apply dev → staging → prod
│       ├── cdk-deploy.yml        # CDK deploy dev → staging → prod on merge to main
│       └── ml-pipeline.yml       # Manual workflow to trigger a SageMaker pipeline run
│
├── cdk/                          # AWS CDK application (app-layer infrastructure)
│   ├── app.py                    # CDK app entry point
│   ├── cdk.json                  # CDK configuration and context
│   ├── constructs/               # Reusable CDK constructs
│   ├── lambda/                   # Lambda function source code
│   │   ├── health/
│   │   │   └── health.py         # Health check endpoint handler
│   │   ├── pipeline_trigger/
│   │   │   └── trigger.py        # Triggers SageMaker pipeline runs
│   │   └── predict/
│   │       └── predict.py        # Inference / prediction handler
│   └── stacks/                   # CDK stack definitions
│       ├── __init__.py
│       ├── inference_api_stack.py # API Gateway + predict Lambda stack
│       ├── monitoring_stack.py    # CloudWatch alarms and dashboards
│       └── pipeline_trigger_stack.py # Pipeline trigger Lambda stack
│
├── notebooks/                    # Jupyter notebooks organised by ML lifecycle stage
│   ├── eda/
│   │   └── eda_exploration.ipynb # Exploratory data analysis
│   ├── training/
│   │   └── model_training.ipynb  # Model training experiments
│   ├── evaluation/
│   │   └── model_evaluation.ipynb # Model evaluation and metrics
│   └── deployment/
│       └── deployment_testing.ipynb # Post-deployment smoke tests
│
├── scripts/                      # Standalone Python utility scripts
│   ├── preprocessing.py          # Data preprocessing pipeline
│   └── evaluate.py               # Offline model evaluation
│
├── terraform/                    # Terraform (foundational infrastructure)
│   ├── environments/             # Per-environment variable overrides
│   │   ├── dev/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── terraform.tfvars
│   │   ├── staging/
│   │   └── prod/
│   └── modules/                  # Reusable Terraform modules
│       ├── iam/                  # IAM roles and policies
│       ├── s3/                   # S3 buckets (data, model artefacts)
│       ├── vpc/                  # VPC, subnets, security groups
│       ├── sagemaker_studio/     # SageMaker Studio domain
│       ├── sagemaker_pipelines/  # SageMaker Pipelines definitions
│       ├── sagemaker_feature_store/ # Feature Store configuration
│       └── sagemaker_endpoints/  # SageMaker real-time endpoints
│
├── docs/                         # Architecture diagrams and documentation
├── requirements.txt              # Python dependencies
└── Makefile                      # Common commands (deploy, test, lint, etc.)
```

---

## Infrastructure Overview

This project uses a two-layer infrastructure approach:

**Terraform** manages foundational, long-lived AWS resources — networking (VPC), storage (S3), IAM, and SageMaker platform resources (Studio, Pipelines, Feature Store, Endpoints). These are provisioned once per environment and rarely change.

**AWS CDK** manages application-layer resources that are tightly coupled to the codebase — Lambda functions, API Gateway, and CloudWatch monitoring. CDK is re-deployed on each release alongside the application code.

**GitHub Actions** automates both layers. Every pull request gets a Terraform plan posted as a comment and a CDK synth dry-run. Merging to `main` automatically deploys to `dev`, then gates on manual approval before promoting to `staging` and `prod`.

---

## Environments

| Environment | Purpose |
|-------------|---------|
| `dev`       | Development and experimentation |
| `staging`   | Pre-production validation |
| `prod`      | Live production environment |

---

## CI/CD Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `ci.yml` | Every push / PR | Lint Python, validate Terraform, CDK synth dry-run |
| `terraform.yml` | PR touching `terraform/` | Posts Terraform plan as a PR comment |
| `terraform.yml` | Merge to `main` | Applies Terraform: dev → staging (approval) → prod (approval) |
| `cdk-deploy.yml` | Merge to `main` touching `cdk/` | Deploys CDK stacks: dev → staging (approval) → prod (approval) |
| `ml-pipeline.yml` | Manual (`workflow_dispatch`) | Triggers a SageMaker pipeline run in any environment |

### GitHub Setup (one-time)

Before the workflows can run, configure the following in your GitHub repository:

**Secrets** (Settings → Secrets and variables → Actions):
- `AWS_ROLE_TO_ASSUME` — IAM role ARN for dev (OIDC, no long-lived keys needed)
- `AWS_ROLE_TO_ASSUME_STAGING` — IAM role ARN for staging
- `AWS_ROLE_TO_ASSUME_PROD` — IAM role ARN for prod

**Environments** (Settings → Environments): Create `dev`, `staging`, and `prod`. Add required reviewers to `staging` and `prod` to enforce manual approval gates before production deploys.

---

## Getting Started

### Option A — Dev Container (recommended)

The fastest way to get a fully configured environment. Requires [Docker Desktop](https://www.docker.com/products/docker-desktop/) and the [VS Code Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers).

1. Clone the repo and open it in VS Code
2. When prompted, click **Reopen in Container** (or run `Dev Containers: Reopen in Container` from the command palette)
3. Wait ~2 minutes for the container to build — `post-create.sh` will install all dependencies automatically

The container includes Python 3.12, Terraform 1.8, AWS CDK v2, AWS CLI v2, and all Python packages from `requirements.txt`. Your local `~/.aws` credentials are mounted in automatically so you're authenticated from the first terminal.

**Works identically in GitHub Codespaces** — open the repo on GitHub and click "Code → Codespaces → Create codespace".

### Option B — Local setup (pyenv + venv)

If you prefer to work outside Docker:

```bash
pyenv local 3.12.0            # pins version via .python-version
python -m venv .venv
source .venv/bin/activate
make install
```

Also install Terraform and AWS CDK manually:
```bash
# Terraform (via tfenv or direct download)
brew install tfenv && tfenv install 1.8.5

# AWS CDK
npm install -g aws-cdk

# AWS CLI
brew install awscli
```

### Provision infrastructure (Terraform)

```bash
make tf-init ENV=dev
make tf-plan ENV=dev
make tf-apply ENV=dev
```

### Deploy application layer (CDK)

```bash
make cdk-bootstrap ENV=dev   # first time only
make cdk-deploy ENV=dev
```

### Run notebooks

Inside the dev container, type `lab` in the terminal to start Jupyter Lab on port 8888 (auto-forwarded to your browser). Otherwise launch JupyterLab or SageMaker Studio and open notebooks from the `notebooks/` directory in order (01 → 04).

---

## Common Commands

```bash
make lint                   # Lint Python + check Terraform fmt
make tf-plan ENV=dev        # Terraform plan for dev
make tf-apply ENV=dev       # Terraform apply for dev
make cdk-synth ENV=dev      # CDK synth (dry run)
make cdk-deploy ENV=dev     # Deploy all CDK stacks to dev
make deploy-all ENV=dev     # Terraform + CDK in one shot
```
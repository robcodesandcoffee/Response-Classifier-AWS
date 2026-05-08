###############################################################################
# SageMaker ML Platform — Makefile
# Usage: make <target> ENV=dev
###############################################################################

ENV         ?= dev
TF_DIR      := terraform/environments/$(ENV)
CDK_DIR     := cdk
REGION      ?= eu-west-2

.PHONY: help tf-init tf-plan tf-apply tf-destroy \
        cdk-bootstrap cdk-synth cdk-deploy cdk-destroy \
        lint clean

help:                           ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-25s\033[0m %s\n", $$1, $$2}'

# ---------------------------------------------------------------------------
# Terraform Aliases
# ---------------------------------------------------------------------------
tf-init:                        ## Initialise Terraform (ENV=dev)
	cd $(TF_DIR) && terraform init

tf-plan:                        ## Plan changes, save binary and generate readable markdown in docs/ (ENV=dev)
	cd $(TF_DIR) && terraform plan -var-file=terraform.tfvars -out=tfplan.$(ENV)
	@printf "# Terraform Plan — $(ENV) — $$(date '+%Y-%m-%d %H:%M')\n\n\`\`\`\n" > docs/tfplan.$(ENV).md
	cd $(TF_DIR) && terraform show -no-color tfplan.$(ENV) >> ../../../docs/tfplan.$(ENV).md
	@printf "\`\`\`\n" >> docs/tfplan.$(ENV).md
	@echo "Plan saved to docs/tfplan.$(ENV).md"

tf-apply:                       ## Apply Terraform changes (ENV=dev)
	cd $(TF_DIR) && terraform apply -var-file=terraform.tfvars -auto-approve

tf-destroy:                     ## Destroy Terraform resources (ENV=dev) — CAREFUL!
	cd $(TF_DIR) && terraform destroy -var-file=terraform.tfvars

tf-output:                      ## Show Terraform outputs (ENV=dev)
	cd $(TF_DIR) && terraform output

tf-fmt:                         ## Format all Terraform files
	terraform fmt -recursive terraform/

tf-validate:                    ## Validate Terraform configuration
	cd $(TF_DIR) && terraform validate

# ---------------------------------------------------------------------------
# AWS CDK Aliases
# ---------------------------------------------------------------------------
cdk-bootstrap:                  ## Bootstrap CDK in account/region
	cd $(CDK_DIR) && cdk bootstrap aws://$$(aws sts get-caller-identity --query Account --output text)/$(REGION) --context env=$(ENV)

cdk-synth:                      ## Synthesise CDK stacks (ENV=dev)
	cd $(CDK_DIR) && cdk synth --context env=$(ENV)

cdk-deploy:                     ## Deploy ALL CDK stacks (ENV=dev)
	cd $(CDK_DIR) && cdk deploy --all --context env=$(ENV) --require-approval never

cdk-deploy-api:                 ## Deploy only the Inference API stack
	cd $(CDK_DIR) && cdk deploy MLPlatformApiStack-$(ENV) --context env=$(ENV)

cdk-deploy-trigger:             ## Deploy only the Pipeline Trigger stack
	cd $(CDK_DIR) && cdk deploy MLPlatformPipelineTriggerStack-$(ENV) --context env=$(ENV)

cdk-deploy-monitoring:          ## Deploy only the Monitoring stack
	cd $(CDK_DIR) && cdk deploy MLPlatformMonitoringStack-$(ENV) --context env=$(ENV)

cdk-destroy:                    ## Destroy ALL CDK stacks (ENV=dev) — CAREFUL!
	cd $(CDK_DIR) && cdk destroy --all --context env=$(ENV)

cdk-diff:                       ## Show CDK diff (ENV=dev)
	cd $(CDK_DIR) && cdk diff --context env=$(ENV)

# ---------------------------------------------------------------------------
# Code quality
# ---------------------------------------------------------------------------
lint:                           ## Lint Python files
	flake8 cdk/ scripts/ --max-line-length=120
	terraform fmt -check -recursive terraform/

# ---------------------------------------------------------------------------
# Full deploy (Terraform then CDK)
# ---------------------------------------------------------------------------
deploy-all: tf-init tf-apply cdk-deploy  ## Deploy everything (Terraform + CDK)
	@echo "Full deployment complete for ENV=$(ENV)"

# ---------------------------------------------------------------------------
# Cleanup
# ---------------------------------------------------------------------------
clean:                          ## Remove local build artefacts
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name .pytest_cache -exec rm -rf {} + 2>/dev/null || true
	find . -name "*.pyc" -delete 2>/dev/null || true
	rm -rf cdk/cdk.out 2>/dev/null || true
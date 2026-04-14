#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# post-create.sh — runs once after the container is built
# Sets up the Python venv, installs dependencies, and configures Terraform.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Response Classifier AWS — Dev Container Setup"
echo "════════════════════════════════════════════════════════"
echo ""

# ── 1. Python virtual environment ─────────────────────────────────────────────
echo "▶ Creating Python virtual environment..."
python -m venv /workspace/.venv
source /workspace/.venv/bin/activate

echo "▶ Upgrading pip..."
pip install --quiet --upgrade pip setuptools wheel

echo "▶ Installing Python dependencies from requirements.txt..."
pip install --quiet -r /workspace/requirements.txt

echo "▶ Installing dev tools (flake8, black, ipykernel)..."
pip install --quiet flake8 black ipykernel

# Register the venv as a Jupyter kernel so notebooks pick it up automatically
python -m ipykernel install --user --name=response-classifier --display-name "Response Classifier (Python 3.12)"

echo "  ✓ Python venv ready at /workspace/.venv"
echo ""

# ── 2. Terraform ──────────────────────────────────────────────────────────────
echo "▶ Verifying Terraform..."
terraform version
echo ""

# ── 3. AWS CDK ────────────────────────────────────────────────────────────────
echo "▶ Verifying AWS CDK..."
cdk --version
echo ""

# ── 4. AWS CLI ────────────────────────────────────────────────────────────────
echo "▶ Verifying AWS CLI..."
aws --version

# Check if AWS credentials are available (mounted from host)
if aws sts get-caller-identity &>/dev/null; then
    echo "  ✓ AWS credentials detected — you're authenticated"
    aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table
else
    echo "  ⚠ No AWS credentials found."
    echo "    Run 'aws configure' in the terminal, or mount your ~/.aws directory."
fi
echo ""

# ── 5. Git config reminder ────────────────────────────────────────────────────
if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    echo "  ⚠ Git user.email is not set."
    echo "    Run: git config --global user.email 'you@example.com'"
    echo "         git config --global user.name 'Your Name'"
    echo ""
fi

# ── 6. Shell convenience aliases ──────────────────────────────────────────────
ALIASES_FILE="/root/.bash_aliases"
cat >> "$ALIASES_FILE" << 'EOF'

# Response Classifier AWS — convenience aliases
alias activate="source /workspace/.venv/bin/activate"
alias tf="terraform"
alias tfplan="make tf-plan ENV=dev"
alias tfapply="make tf-apply ENV=dev"
alias cdkdeploy="make cdk-deploy ENV=dev"
alias cdksynth="make cdk-synth ENV=dev"
alias lab="jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=/workspace/notebooks"
EOF

echo "▶ Shell aliases added (activate, tf, tfplan, tfapply, cdkdeploy, cdksynth, lab)"
echo ""

# ── Done ──────────────────────────────────────────────────────────────────────
echo "════════════════════════════════════════════════════════"
echo "  Setup complete! Tips:"
echo ""
echo "  • The Python venv is auto-activated in every terminal"
echo "  • Type 'lab' to start Jupyter Lab on port 8888"
echo "  • Type 'tfplan' to run terraform plan for dev"
echo "  • Type 'cdkdeploy' to deploy CDK stacks to dev"
echo "════════════════════════════════════════════════════════"
echo ""

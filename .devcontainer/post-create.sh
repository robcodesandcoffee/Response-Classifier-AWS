#!/usr/bin/env bash
# post-create.sh — runs once after the container is built
set -e

WORKSPACE_DIR="$(pwd)"

echo ""
echo "════════════════════════════════════════════════════════"
echo "  Response Classifier AWS — Dev Container Setup"
echo "  Workspace: ${WORKSPACE_DIR}"
echo "════════════════════════════════════════════════════════"
echo ""

# ── Ensure feature-installed tools are on PATH ────────────────────────────────
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"
for f in /etc/profile.d/*.sh; do
    [ -r "$f" ] && . "$f" || true
done

# ── Diagnostics ───────────────────────────────────────────────────────────────
echo "▶ Tool check:"
command -v python    &>/dev/null && echo "  python    : $(python --version)"            || echo "  python    : NOT FOUND"
command -v terraform &>/dev/null && echo "  terraform : $(terraform version | head -1)" || echo "  terraform : NOT FOUND"
command -v aws       &>/dev/null && echo "  aws-cli   : $(aws --version 2>&1)"          || echo "  aws-cli   : NOT FOUND"
echo ""

# ── System dependency ─────────────────────────────────────────────────────────
echo "▶ Installing libgomp1 (required by XGBoost / LightGBM)..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends libgomp1
sudo rm -rf /var/lib/apt/lists/*
echo ""

# ── Python packages ───────────────────────────────────────────────────────────
# Installed directly into the container — no venv needed, Docker is the isolation layer
echo "▶ Installing Python packages..."
python -m pip install --quiet --upgrade pip setuptools wheel

python -m pip install --quiet \
    `# AWS & SageMaker` \
    sagemaker boto3 botocore \
    `# Data science` \
    pandas numpy scikit-learn xgboost lightgbm shap \
    `# Visualisation` \
    matplotlib seaborn plotly \
    `# MLOps` \
    mlflow \
    `# AWS CDK (Python)` \
    aws-cdk-lib constructs \
    `# Utilities` \
    python-dotenv pyyaml requests tqdm \
    `# Dev tools` \
    flake8 black

echo "  ✓ Python packages installed"
echo ""

# ── AWS credentials check ─────────────────────────────────────────────────────
if command -v aws &>/dev/null && aws sts get-caller-identity &>/dev/null; then
    echo "  ✓ AWS credentials detected"
    aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table
else
    echo "  ⚠ No AWS credentials — run 'aws configure' in the terminal"
fi
echo ""

# ── Git config reminder ───────────────────────────────────────────────────────
if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    echo "  ⚠ Git email not set:"
    echo "    git config --global user.email 'you@example.com'"
    echo "    git config --global user.name  'Your Name'"
    echo ""
fi

# ── Shell aliases ─────────────────────────────────────────────────────────────
cat >> "${HOME}/.bash_aliases" << EOF

# Response Classifier AWS
alias tf="terraform"
alias tfplan="make tf-plan ENV=dev"
alias tfapply="make tf-apply ENV=dev"
EOF

echo "════════════════════════════════════════════════════════"
echo "  Ready! Useful commands:"
echo "  tfplan   — terraform plan for dev"
echo "  tfapply  — terraform apply for dev"
echo "════════════════════════════════════════════════════════"
echo ""
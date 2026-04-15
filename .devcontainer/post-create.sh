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

# ── Diagnostics — print what's available before doing any work ────────────────
echo "▶ Tool availability check:"
command -v python    &>/dev/null && echo "  python    : $(python --version)"          || echo "  python    : NOT FOUND"
command -v terraform &>/dev/null && echo "  terraform : $(terraform version | head -1)" || echo "  terraform : NOT FOUND"
command -v aws       &>/dev/null && echo "  aws-cli   : $(aws --version 2>&1)"        || echo "  aws-cli   : NOT FOUND"
echo ""

# ── 1. System package: libgomp1 (required by XGBoost / LightGBM) ─────────────
echo "▶ Installing libgomp1..."
sudo apt-get update -qq
sudo apt-get install -y --no-install-recommends libgomp1
sudo rm -rf /var/lib/apt/lists/*
echo "  ✓ libgomp1 installed"
echo ""

# ── 2. Python virtual environment ─────────────────────────────────────────────
echo "▶ Upgrading pip..."
python -m pip install --quiet --upgrade pip setuptools wheel

echo "▶ Installing Python dependencies..."
python -m pip install --quiet -r "${WORKSPACE_DIR}/requirements.txt"

echo "▶ Installing dev tools (flake8, black, ipykernel)..."
python -m pip install --quiet flake8 black ipykernel

echo "▶ Registering Jupyter kernel..."
python -m ipykernel install --user \
    --name=response-classifier \
    --display-name "Response Classifier (Python 3.12)"

echo "  ✓ Python packages installed"
echo ""

# ── 4. AWS credentials check (non-fatal) ─────────────────────────────────────
if command -v aws &>/dev/null && aws sts get-caller-identity &>/dev/null; then
    echo "  ✓ AWS credentials detected"
    aws sts get-caller-identity --query '{Account:Account,Arn:Arn}' --output table
else
    echo "  ⚠ No AWS credentials — run 'aws configure' in the terminal"
fi
echo ""

# ── 5. Git config reminder (non-fatal) ───────────────────────────────────────
if [ -z "$(git config --global user.email 2>/dev/null)" ]; then
    echo "  ⚠ Git email not set:"
    echo "    git config --global user.email 'you@example.com'"
    echo "    git config --global user.name 'Your Name'"
    echo ""
fi

# ── 6. Shell aliases ──────────────────────────────────────────────────────────
ALIASES_FILE="${HOME}/.bash_aliases"
cat >> "$ALIASES_FILE" << EOF

# Response Classifier AWS
alias tf="terraform"
alias tfplan="make tf-plan ENV=dev"
alias tfapply="make tf-apply ENV=dev"
alias cdkdeploy="make cdk-deploy ENV=dev"
alias cdksynth="make cdk-synth ENV=dev"
alias lab="jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --notebook-dir=${WORKSPACE_DIR}/notebooks"
EOF
echo "▶ Shell aliases written to ${ALIASES_FILE}"
echo ""

echo "════════════════════════════════════════════════════════"
echo "  Setup complete!"
echo "  • Type 'activate' to activate the Python venv"
echo "  • Type 'lab' to start Jupyter Lab on port 8888"
echo "  • Type 'tfplan' to run terraform plan for dev"
echo "════════════════════════════════════════════════════════"
echo ""
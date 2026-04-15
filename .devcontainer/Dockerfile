# ─────────────────────────────────────────────────────────────────────────────
# Response Classifier AWS — Dev Container
#
# Includes:
#   - Python 3.12
#   - Terraform 1.8
#   - AWS CDK v2 (Node 20)
#   - AWS CLI v2
#   - Common ML/data science system deps
# ─────────────────────────────────────────────────────────────────────────────

FROM mcr.microsoft.com/devcontainers/python:3.12-bullseye

ARG TERRAFORM_VERSION=1.8.5
ARG NODE_VERSION=20

# ── System packages ───────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    gnupg \
    lsb-release \
    make \
    git \
    jq \
    less \
    groff \
    # Required by some Python ML packages
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js (for AWS CDK) ─────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── AWS CDK v2 (global) ───────────────────────────────────────────────────────
RUN npm install -g aws-cdk

# ── Terraform ─────────────────────────────────────────────────────────────────
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o /tmp/terraform.zip \
    && unzip /tmp/terraform.zip -d /usr/local/bin \
    && rm /tmp/terraform.zip \
    && terraform version

# ── AWS CLI v2 ────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o /tmp/awscliv2.zip \
    && unzip /tmp/awscliv2.zip -o -d /tmp \
    && /tmp/aws/install \
    && rm -rf /tmp/awscliv2.zip /tmp/aws \
    && aws --version

# ── Python pip upgrade ────────────────────────────────────────────────────────
RUN pip install --upgrade pip setuptools wheel

# Set working directory — VS Code will mount the repo here
WORKDIR /workspace

################################################################################
# SageMaker Studio Module — single ML engineer setup
################################################################################

data "aws_region" "current" {}

# ---------------------------------------------------------------------------
# Pre-destroy: delete all Studio apps before Terraform removes the user
# profile and domain. SageMaker rejects profile/domain deletion while any
# app is in a non-Deleted state (InService, Pending, Deleting).
# This null_resource depends on both resources so it is destroyed first,
# giving the destroy provisioner a chance to clean up before they are removed.
# ---------------------------------------------------------------------------
resource "null_resource" "delete_sagemaker_apps" {
  triggers = {
    domain_id         = aws_sagemaker_domain.studio.id
    user_profile_name = aws_sagemaker_user_profile.ml_engineer.user_profile_name
    region            = data.aws_region.current.name
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOF
      DOMAIN_ID="${self.triggers.domain_id}"
      REGION="${self.triggers.region}"

      echo "Deleting all SageMaker Studio apps in domain $DOMAIN_ID..."

      aws sagemaker list-apps \
        --domain-id-equals "$DOMAIN_ID" \
        --region "$REGION" \
        --query 'Apps[?Status!=`Deleted`].[DomainId,UserProfileName,AppType,AppName]' \
        --output text | \
      while IFS=$'\t' read -r d u t n; do
        [ -z "$n" ] && continue
        echo "  Deleting app: $n ($t)"
        aws sagemaker delete-app \
          --domain-id "$d" \
          --user-profile-name "$u" \
          --app-type "$t" \
          --app-name "$n" \
          --region "$REGION" 2>/dev/null || true
      done

      echo "Waiting for apps to finish deleting..."
      for i in $(seq 1 30); do
        COUNT=$(aws sagemaker list-apps \
          --domain-id-equals "$DOMAIN_ID" \
          --region "$REGION" \
          --query 'length(Apps[?Status!=`Deleted`])' \
          --output text 2>/dev/null || echo "0")
        [ "$COUNT" = "0" ] && echo "All apps deleted." && exit 0
        echo "  $COUNT app(s) still deleting ($i/30)..."
        sleep 20
      done
      echo "Warning: some apps may still be deleting — terraform destroy may need a retry."
      exit 0
    EOF
  }

  depends_on = [
    aws_sagemaker_user_profile.ml_engineer,
    aws_sagemaker_domain.studio,
  ]
}

resource "aws_sagemaker_domain" "studio" {
  domain_name = "${var.project}-${var.environment}-studio"
  auth_mode   = "SSO"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.security_group_id]

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.auto_install.arn]
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "system"
      }
      lifecycle_config_arns = [aws_sagemaker_studio_lifecycle_config.auto_install.arn]
    }
  }

  app_network_access_type = "VpcOnly"

  # Delete the auto-provisioned EFS file system when the domain is destroyed.
  # Without this, EFS + its mount targets are retained and block subnet/VPC
  # deletion with a DependencyViolation.
  retention_policy {
    home_efs_file_system = "Delete"
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-studio" })
}

# ---------------------------------------------------------------------------
# Single user profile — linked to IAM Identity Center username
# ---------------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "ml_engineer" {
  domain_id         = aws_sagemaker_domain.studio.id
  user_profile_name = var.sso_username

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.security_group_id]

    # Default to smallest CPU instance — engineer can change at launch time
    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = "ml.t3.medium"
      }
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Lifecycle config — minimal packages for response classification work
# Runs once when a kernel starts — keep it lean to reduce startup time
# ---------------------------------------------------------------------------
resource "aws_sagemaker_studio_lifecycle_config" "auto_install" {
  studio_lifecycle_config_name     = "${var.project}-${var.environment}-auto-install"
  studio_lifecycle_config_app_type = "KernelGateway"

  studio_lifecycle_config_content = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    pip install --upgrade pip --quiet
    pip install --quiet \
      "sagemaker>=2.200.0" \
      "boto3>=1.34.0" \
      pandas \
      scikit-learn \
      xgboost \
      matplotlib
    echo "Lifecycle config complete"
  EOF
  )

  tags = var.tags
}

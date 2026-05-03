################################################################################
# SageMaker Studio Module — single ML engineer setup
################################################################################

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

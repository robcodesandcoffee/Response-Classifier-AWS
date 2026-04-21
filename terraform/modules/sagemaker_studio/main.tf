################################################################################
# SageMaker Studio Module
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

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path         = "s3://${var.artifacts_bucket_name}/studio-outputs/"
    }
  }

  app_network_access_type = "VpcOnly"

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-studio" })
}

# ---------------------------------------------------------------------------
# User profile — must match the IAM Identity Center username (e.g. email prefix)
# ---------------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "default" {
  domain_id         = aws_sagemaker_domain.studio.id
  user_profile_name = var.sso_username

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.security_group_id]
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Lifecycle config — installs packages when a kernel starts
# ---------------------------------------------------------------------------
resource "aws_sagemaker_studio_lifecycle_config" "auto_install" {
  studio_lifecycle_config_name     = "${var.project}-${var.environment}-auto-install"
  studio_lifecycle_config_app_type = "KernelGateway"

  studio_lifecycle_config_content = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    pip install --upgrade pip --quiet
    pip install --quiet \
      pandas \
      scikit-learn \
      xgboost \
      lightgbm \
      matplotlib \
      seaborn \
      plotly \
      shap \
      "sagemaker>=2.200.0" \
      "boto3>=1.34.0"
    echo "Lifecycle config complete"
  EOF
  )

  tags = var.tags
}

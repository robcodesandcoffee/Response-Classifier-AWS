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

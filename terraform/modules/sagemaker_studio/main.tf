################################################################################
# SageMaker Studio Module
################################################################################

resource "aws_sagemaker_domain" "studio" {
  domain_name = "${var.project}-${var.environment}-studio"
  auth_mode   = "IAM"
  vpc_id      = var.vpc_id
  subnet_ids  = var.subnet_ids

  default_user_settings {
    execution_role = var.execution_role_arn

    security_groups = [var.security_group_id]

    jupyter_server_app_settings {
      default_resource_spec {
        instance_type       = "system"
        sagemaker_image_arn = data.aws_sagemaker_prebuilt_ecr_image.jupyter.registry_path
      }
    }

    kernel_gateway_app_settings {
      default_resource_spec {
        instance_type = var.default_instance_type
      }

      # Allow data science kernels
      custom_image {
        app_image_config_name = aws_sagemaker_app_image_config.data_science.app_image_config_name
        image_name            = aws_sagemaker_image.data_science.image_name
      }
    }

    sharing_settings {
      notebook_output_option = "Allowed"
      s3_output_path         = "s3://${var.artifacts_bucket_name}/studio-outputs/"
    }
  }

  domain_settings {
    execution_role_identity_config = "USER_PROFILE_NAME"
  }

  app_network_access_type = "VpcOnly"

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-studio" })
}

data "aws_sagemaker_prebuilt_ecr_image" "jupyter" {
  repository_name = "sagemaker-data-science-310-v1"
}

resource "aws_sagemaker_image" "data_science" {
  image_name = "${var.project}-${var.environment}-data-science"
  role_arn   = var.execution_role_arn
  tags       = var.tags
}

resource "aws_sagemaker_app_image_config" "data_science" {
  app_image_config_name = "${var.project}-${var.environment}-data-science-config"

  kernel_gateway_image_config {
    kernel_spec {
      name         = "python3"
      display_name = "Python 3 (Data Science)"
    }

    file_system_config {
      mount_path        = "/home/sagemaker-user"
      default_uid       = 1000
      default_gid       = 100
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Default user profile
# ---------------------------------------------------------------------------
resource "aws_sagemaker_user_profile" "default" {
  domain_id         = aws_sagemaker_domain.studio.id
  user_profile_name = "default-user"

  user_settings {
    execution_role  = var.execution_role_arn
    security_groups = [var.security_group_id]
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Studio lifecycle config — installs common ML packages on startup
# ---------------------------------------------------------------------------
resource "aws_sagemaker_studio_lifecycle_config" "auto_install" {
  studio_lifecycle_config_name     = "${var.project}-${var.environment}-auto-install"
  studio_lifecycle_config_app_type = "KernelGateway"

  studio_lifecycle_config_content = base64encode(<<-EOF
    #!/bin/bash
    set -eux
    pip install --upgrade pip
    pip install \
      pandas==2.1.4 \
      scikit-learn==1.3.2 \
      xgboost==2.0.3 \
      lightgbm==4.2.0 \
      matplotlib==3.8.2 \
      seaborn==0.13.1 \
      plotly==5.18.0 \
      shap==0.44.0 \
      sagemaker>=2.200.0 \
      boto3>=1.34.0 \
      mlflow==2.10.0
    echo "Packages installed successfully"
  EOF
  )

  tags = var.tags
}

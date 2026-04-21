################################################################################
# Root configuration — dev environment
################################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "codesandcoffee-project-tfstate"
    key            = "response-classifier/dev/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "response-classifier-tfstate-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
    Team        = var.team
  }
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------
module "vpc" {
  source = "../../modules/vpc"

  project              = var.project
  environment          = var.environment
  region               = var.region
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  tags                 = local.common_tags
}

# ---------------------------------------------------------------------------
# S3 buckets
# ---------------------------------------------------------------------------
module "s3" {
  source = "../../modules/s3"

  project     = var.project
  environment = var.environment
  account_id  = data.aws_caller_identity.current.account_id
  tags        = local.common_tags
}

# ---------------------------------------------------------------------------
# IAM roles
# ---------------------------------------------------------------------------
module "iam" {
  source = "../../modules/iam"

  project               = var.project
  environment           = var.environment
  data_bucket_name      = module.s3.data_bucket_name
  artifacts_bucket_name = module.s3.artifacts_bucket_name
  models_bucket_name    = module.s3.models_bucket_name
  tags                  = local.common_tags
}

# ---------------------------------------------------------------------------
# SageMaker Studio
# ---------------------------------------------------------------------------
module "sagemaker_studio" {
  source = "../../modules/sagemaker_studio"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.vpc.sagemaker_sg_id
  execution_role_arn    = module.iam.sagemaker_execution_role_arn
  artifacts_bucket_name = module.s3.artifacts_bucket_name
  sso_username          = var.sso_username
  tags                  = local.common_tags
}

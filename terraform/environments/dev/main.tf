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

  #backend "s3" {
  # Populate these before first apply:
  # bucket         = "codesandcoffee-project-tfstate"
  # key            = "response-classifier/dev/terraform.tfstate"
  # region         = "eu-west-2"
  # dynamodb_table = "tfstate-lock-table"
  # encrypt        = true
  #}
}

provider "aws" {
  region = var.region
}

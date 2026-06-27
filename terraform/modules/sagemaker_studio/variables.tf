variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "execution_role_arn" {
  type = string
}

variable "artifacts_bucket_name" {
  type = string
}

variable "sso_username" {
  description = "IAM Identity Center username — must match exactly to link the Studio profile to your SSO login"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9](-*[a-zA-Z0-9]){0,62}$", var.sso_username))
    error_message = "SSO username must be a valid SageMaker user profile name: letters, numbers, and hyphens only, no underscores, max 63 characters, and cannot begin or end with a hyphen."
  }
}

variable "tags" {
  type    = map(string)
  default = {}
}

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
}

variable "tags" {
  type    = map(string)
  default = {}
}

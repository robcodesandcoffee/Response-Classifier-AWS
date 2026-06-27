variable "project" {
  type    = string
  default = "response-classifier"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "team" {
  type    = string
  default = "data-science"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Single AZ for dev — add a second for staging/prod"
  default     = ["10.0.10.0/24"]
}

variable "availability_zones" {
  type        = list(string)
  description = "Single AZ for dev — add a second for staging/prod"
  default     = ["eu-west-2a"]
}

variable "training_instance_type" {
  type    = string
  default = "ml.m5.xlarge"
}

variable "sso_username" {
  description = "IAM Identity Center username — must match exactly (check in IAM Identity Center → Users). SageMaker Studio user profile names allow only letters, numbers, and hyphens."
  type        = string
}

# Leave empty to skip endpoint creation until a model has been trained
variable "model_artifact_s3_uri" {
  type    = string
  default = ""
}

variable "project" {
  type    = string
  default = "ml-platform"
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
  default = "us-east-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "studio_default_instance_type" {
  type    = string
  default = "ml.t3.medium"
}

variable "training_instance_type" {
  type    = string
  default = "ml.m5.xlarge"
}

# Leave empty to skip endpoint creation until a model has been trained
variable "model_artifact_s3_uri" {
  type    = string
  default = ""
}

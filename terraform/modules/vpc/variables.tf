variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.10.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["eu-west-2a"]
}

variable "tags" {
  type    = map(string)
  default = {}
}

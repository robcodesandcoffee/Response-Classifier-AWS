variable "project"               { type = string }
variable "environment"           { type = string }
variable "vpc_id"                { type = string }
variable "subnet_ids"            { type = list(string) }
variable "security_group_id"     { type = string }
variable "execution_role_arn"    { type = string }
variable "artifacts_bucket_name" { type = string }
variable "default_instance_type" { type = string; default = "ml.t3.medium" }
variable "tags"                  { type = map(string); default = {} }

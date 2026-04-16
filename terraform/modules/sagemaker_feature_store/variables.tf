variable "project"            { type = string }
variable "environment"        { type = string }
variable "execution_role_arn" { type = string }
variable "data_bucket_name"   { type = string }
variable "tags"               { type = map(string); default = {} }

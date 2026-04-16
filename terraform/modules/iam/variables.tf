variable "project"              { type = string }
variable "environment"          { type = string }
variable "data_bucket_name"     { type = string }
variable "artifacts_bucket_name" { type = string }
variable "models_bucket_name"   { type = string }
variable "tags"                 { type = map(string); default = {} }

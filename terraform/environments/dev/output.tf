output "vpc_id" { value = module.vpc.vpc_id }
output "private_subnet_ids" { value = module.vpc.private_subnet_ids }
output "data_bucket" { value = module.s3.data_bucket_name }
output "artifacts_bucket" { value = module.s3.artifacts_bucket_name }
output "models_bucket" { value = module.s3.models_bucket_name }
output "sagemaker_execution_role_arn" { value = module.iam.sagemaker_execution_role_arn }
output "studio_domain_id" { value = module.sagemaker_studio.domain_id }

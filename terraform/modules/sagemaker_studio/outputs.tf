output "domain_id" { value = aws_sagemaker_domain.studio.id }
output "domain_arn" { value = aws_sagemaker_domain.studio.arn }
output "default_user_profile" { value = aws_sagemaker_user_profile.default.user_profile_name }
output "lifecycle_config_arn" { value = aws_sagemaker_studio_lifecycle_config.auto_install.arn }

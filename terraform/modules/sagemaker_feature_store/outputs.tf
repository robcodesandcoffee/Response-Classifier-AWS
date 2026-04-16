output "customer_feature_group_name"     { value = aws_sagemaker_feature_group.customer_features.feature_group_name }
output "transaction_feature_group_name"  { value = aws_sagemaker_feature_group.transaction_features.feature_group_name }
output "glue_database_name"              { value = aws_glue_catalog_database.feature_store.name }

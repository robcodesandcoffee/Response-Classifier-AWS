output "data_bucket_name"      { value = aws_s3_bucket.this["data"].bucket }
output "data_bucket_arn"       { value = aws_s3_bucket.this["data"].arn }
output "artifacts_bucket_name" { value = aws_s3_bucket.this["artifacts"].bucket }
output "artifacts_bucket_arn"  { value = aws_s3_bucket.this["artifacts"].arn }
output "models_bucket_name"    { value = aws_s3_bucket.this["models"].bucket }
output "models_bucket_arn"     { value = aws_s3_bucket.this["models"].arn }
output "logs_bucket_name"      { value = aws_s3_bucket.this["logs"].bucket }

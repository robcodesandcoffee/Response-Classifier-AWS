################################################################################
# IAM Module — single SageMaker execution role
#
# This role is attached to the Studio domain and passed to any training job,
# pipeline, or endpoint the notebook creates. AmazonSageMakerFullAccess
# already covers ECR pulls for AWS-managed SageMaker images, so no separate
# ECR policy is needed.
################################################################################

data "aws_iam_policy_document" "sagemaker_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["sagemaker.amazonaws.com"]
    }
  }
}

# ---------------------------------------------------------------------------
# SageMaker Execution Role (Studio, training jobs, pipelines, endpoints)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "sagemaker_execution" {
  name               = "${var.project}-${var.environment}-sagemaker-exec-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_s3" {
  name = "${var.project}-${var.environment}-sagemaker-s3-policy"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:AbortMultipartUpload",
          "s3:ListMultipartUploadParts"
        ]
        Resource = [
          "arn:aws:s3:::${var.data_bucket_name}",
          "arn:aws:s3:::${var.data_bucket_name}/*",
          "arn:aws:s3:::${var.artifacts_bucket_name}",
          "arn:aws:s3:::${var.artifacts_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.models_bucket_name}",
          "arn:aws:s3:::${var.models_bucket_name}/*"
        ]
      }
    ]
  })
}

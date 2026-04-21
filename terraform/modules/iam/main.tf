################################################################################
# IAM Module — SageMaker roles & policies
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
# SageMaker Execution Role (Studio, training jobs, pipelines)
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

resource "aws_iam_role_policy" "sagemaker_feature_store" {
  name = "${var.project}-${var.environment}-feature-store-policy"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:CreateFeatureGroup",
          "sagemaker:DescribeFeatureGroup",
          "sagemaker:DeleteFeatureGroup",
          "sagemaker:UpdateFeatureGroup",
          "sagemaker:ListFeatureGroups",
          "sagemaker:PutRecord",
          "sagemaker:GetRecord",
          "sagemaker:DeleteRecord",
          "sagemaker:BatchGetRecord"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["glue:*"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "sagemaker_ecr" {
  name = "${var.project}-${var.environment}-ecr-policy"
  role = aws_iam_role.sagemaker_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Pipeline execution role (can be separate for least-privilege)
# ---------------------------------------------------------------------------
resource "aws_iam_role" "pipeline_execution" {
  name               = "${var.project}-${var.environment}-pipeline-exec-role"
  assume_role_policy = data.aws_iam_policy_document.sagemaker_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "pipeline_sagemaker" {
  role       = aws_iam_role.pipeline_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy_attachment" "pipeline_s3" {
  role       = aws_iam_role.pipeline_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

################################################################################
# S3 Module — data, artifacts, and model buckets
################################################################################

locals {
  buckets = {
    data      = "${var.project}-${var.environment}-data-${var.account_id}"
    artifacts = "${var.project}-${var.environment}-artifacts-${var.account_id}"
    models    = "${var.project}-${var.environment}-models-${var.account_id}"
    logs      = "${var.project}-${var.environment}-logs-${var.account_id}"
  }
}

resource "aws_s3_bucket" "this" {
  for_each      = local.buckets
  bucket        = each.value
  force_destroy = var.environment != "prod"

  tags = merge(var.tags, {
    Name    = each.value
    Purpose = each.key
  })
}

resource "aws_s3_bucket_versioning" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  for_each = aws_s3_bucket.this
  bucket   = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  for_each                = aws_s3_bucket.this
  bucket                  = each.value.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.this["artifacts"].id

  rule {
    id     = "expire-old-pipeline-artifacts"
    status = "Enabled"

    filter { prefix = "pipelines/" }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "models" {
  bucket = aws_s3_bucket.this["models"].id

  rule {
    id     = "transition-old-models-to-ia"
    status = "Enabled"

    filter { prefix = "" }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }
  }
}

# Pre-create common prefixes (SageMaker expects these paths)
resource "aws_s3_object" "prefixes" {
  for_each = toset([
    "raw/",
    "processed/",
    "features/",
    "train/",
    "validation/",
    "test/"
  ])

  bucket  = aws_s3_bucket.this["data"].id
  key     = each.value
  content = ""
}

################################################################################
# SageMaker Feature Store Module
################################################################################

# ---------------------------------------------------------------------------
# Customer features feature group
# ---------------------------------------------------------------------------
resource "aws_sagemaker_feature_group" "customer_features" {
  feature_group_name             = "${var.project}-${var.environment}-customer-features"
  record_identifier_feature_name = "customer_id"
  event_time_feature_name        = "event_time"
  role_arn                       = var.execution_role_arn
  description                    = "Customer-level features for ${var.project}"

  feature_definition {
    feature_name = "customer_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "event_time"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "age"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "tenure_months"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "total_spend_90d"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "num_transactions_90d"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "avg_transaction_value"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "churn_risk_score"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "segment"
    feature_type = "String"
  }

  online_store_config {
    enable_online_store = true
  }

  offline_store_config {
    s3_storage_config {
      s3_uri = "s3://${var.data_bucket_name}/feature-store/customer-features/"
    }
    disable_glue_table_creation = false

    data_catalog_config {
      table_name    = "${replace(var.project, "-", "_")}_${var.environment}_customer_features"
      catalog       = "AwsDataCatalog"
      database      = "${replace(var.project, "-", "_")}_${var.environment}_feature_store"
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Transaction features feature group
# ---------------------------------------------------------------------------
resource "aws_sagemaker_feature_group" "transaction_features" {
  feature_group_name             = "${var.project}-${var.environment}-transaction-features"
  record_identifier_feature_name = "transaction_id"
  event_time_feature_name        = "event_time"
  role_arn                       = var.execution_role_arn
  description                    = "Transaction-level features for ${var.project}"

  feature_definition {
    feature_name = "transaction_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "event_time"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "customer_id"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "amount"
    feature_type = "Fractional"
  }

  feature_definition {
    feature_name = "merchant_category"
    feature_type = "String"
  }

  feature_definition {
    feature_name = "is_online"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "hour_of_day"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "day_of_week"
    feature_type = "Integral"
  }

  feature_definition {
    feature_name = "is_fraud"
    feature_type = "Integral"
  }

  online_store_config {
    enable_online_store = true
  }

  offline_store_config {
    s3_storage_config {
      s3_uri = "s3://${var.data_bucket_name}/feature-store/transaction-features/"
    }
    disable_glue_table_creation = false

    data_catalog_config {
      table_name    = "${replace(var.project, "-", "_")}_${var.environment}_transaction_features"
      catalog       = "AwsDataCatalog"
      database      = "${replace(var.project, "-", "_")}_${var.environment}_feature_store"
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Glue database for the feature store catalog
# ---------------------------------------------------------------------------
resource "aws_glue_catalog_database" "feature_store" {
  name        = "${replace(var.project, "-", "_")}_${var.environment}_feature_store"
  description = "Glue catalog for ${var.project} Feature Store (${var.environment})"
}

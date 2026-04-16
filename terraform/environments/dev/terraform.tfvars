project     = "ml-platform"
environment = "dev"
team        = "data-science"
region      = "us-east-1"

vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

studio_default_instance_type = "ml.t3.medium"
training_instance_type       = "ml.m5.xlarge"

# Uncomment and set this once your first model has been trained:
# model_artifact_s3_uri = "s3://ml-platform-dev-models-<account-id>/model.tar.gz"
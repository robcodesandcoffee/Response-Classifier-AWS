################################################################################
# VPC Module — private subnets + VPC endpoints (no NAT Gateway)
# SageMaker traffic stays on the AWS backbone via interface endpoints
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # required for VPC endpoint DNS resolution
  enable_dns_support   = true # required for VPC endpoint DNS resolution

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-vpc" })
}

# ---------------------------------------------------------------------------
# Private subnets — SageMaker workloads run here
# ---------------------------------------------------------------------------
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project}-${var.environment}-private-${count.index + 1}"
    Tier = "private"
  })
}

# ---------------------------------------------------------------------------
# Route table — local routes only, no internet gateway or NAT
# ---------------------------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-rt-private" })
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------------------------
# Security group for SageMaker Studio and training jobs
# ---------------------------------------------------------------------------
resource "aws_security_group" "sagemaker" {
  name        = "${var.project}-${var.environment}-sagemaker-sg"
  description = "SageMaker Studio and training jobs"
  vpc_id      = aws_vpc.this.id

  # NFS for SageMaker Studio home directory (EFS)
  ingress {
    description = "NFS for EFS (Studio home directory)"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  # Inter-container communication (training jobs)
  ingress {
    description = "Inter-container communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # HTTPS outbound to VPC endpoints only
  egress {
    description = "HTTPS to VPC endpoints"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NFS outbound to EFS
  egress {
    description = "NFS to EFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    self        = true
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-sagemaker-sg" })
}

# ---------------------------------------------------------------------------
# Security group for VPC interface endpoints
# ---------------------------------------------------------------------------
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.environment}-vpce-sg"
  description = "VPC interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTPS from SageMaker resources"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.sagemaker.id]
  }

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-vpce-sg" })
}

# ---------------------------------------------------------------------------
# S3 Gateway endpoint — free, keeps S3 traffic off the internet
# ---------------------------------------------------------------------------
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-vpce-s3" })
}

# ---------------------------------------------------------------------------
# Interface endpoints — SageMaker, CloudWatch, STS
# These replace the NAT Gateway for SageMaker control-plane / runtime traffic.
#
# ECR endpoints (ecr-api / ecr-dkr) intentionally not included: notebook-
# deployed endpoints run in the SageMaker-managed VPC by default, so the
# customer VPC doesn't need to reach ECR. Add them back here if you start
# deploying endpoints inside this VPC with a custom container image.
# ---------------------------------------------------------------------------
locals {
  interface_endpoints = {
    "sagemaker-api"     = "com.amazonaws.${var.region}.sagemaker.api"
    "sagemaker-runtime" = "com.amazonaws.${var.region}.sagemaker.runtime"
    "logs"              = "com.amazonaws.${var.region}.logs"
    "sts"               = "com.amazonaws.${var.region}.sts"
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each = local.interface_endpoints

  vpc_id              = aws_vpc.this.id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpc_endpoints.id]
  private_dns_enabled = true # allows standard AWS SDK calls without endpoint-specific URLs

  tags = merge(var.tags, { Name = "${var.project}-${var.environment}-vpce-${each.key}" })
}

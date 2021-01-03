#
# Enable VPC flow logs for all traffic.
#
resource "aws_flow_log" "this" {
  log_destination      = aws_s3_bucket.this.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id
  tags                 = var.tags
}

#
# Bucket to store VPC flow logs.
#
resource "aws_s3_bucket" "this" {
  bucket = coalesce(var.s3.prefix, var.s3.bucket)
  acl    = "private"

  # Versioning will not be needed for this
  versioning {
    enabled = false
  }

  # Enable encryption at rest
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  # Enable lifecycle:
  #   - After 30 days, data is moved to Standard Infrequent Access
  #   - After 60 days, data is expired
  lifecycle_rule {
    enabled = true

    transition {
      days          = var.s3.lifecycle.transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.s3.lifecycle.expiration_days
    }
  }

  tags = coalescelist(var.s3.tags, var.tags)
}

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.this.id
  policy = <<POLICY
{
  "Id": "TerraformStateBucketPolicies",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EnforceSSlRequestsOnly",
      "Action": "s3:*",
      "Effect": "Deny",
      "Resource": "${aws_s3_bucket.this.arn}/*",
      "Condition": {
         "Bool": {
           "aws:SecureTransport": "false"
          }
      },
      "Principal": "*"
    }
  ]
}
POLICY
}

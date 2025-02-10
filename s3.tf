# S3
resource "aws_s3_bucket" "creator_catalyst_analytics" {
  bucket = "${var.environment}-creator-catalyst-analytics"
  tags = {
    environment = var.environment
  }
}

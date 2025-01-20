resource "aws_athena_workgroup" "creator_workgroup" {
  name = "${var.environment}-creator-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/"
    }
  }
}

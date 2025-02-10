resource "aws_sqs_queue" "creator_catalyst_queue_cc" {
  name = "${var.environment}-dev-queue-cc"
}

resource "aws_sqs_queue" "creator_catalyst_post_processing" {
  name = "${var.environment}-post-processing"
}

resource "aws_sqs_queue" "media_processing" {
  name = "${var.environment}-media-processing"
}

resource "aws_sqs_queue" "metrics_reporting" {
  name = "${var.environment}-metrics-reporting"
}

resource "aws_sqs_queue" "report_batches" {
  name = "${var.environment}-report-batches"
}

resource "aws_sqs_queue" "send_email_queue" {
  name = "${var.environment}-send-email-queue-cc"
}

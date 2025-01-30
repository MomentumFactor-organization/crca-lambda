# Layer for boto3
resource "aws_lambda_layer_version" "boto3_layer" {
  filename            = "layers/compressed/boto3-layer.zip"
  layer_name          = "${var.environment}-boto3-layer"
  compatible_runtimes = ["python3.9", "python3.10"]
  source_code_hash    = filebase64sha256("layers/compressed/boto3-layer.zip")
  description         = "Layer for boto3 library"
}

# Layer for requests
resource "aws_lambda_layer_version" "requests_layer" {
  filename            = "layers/compressed/requests-layer.zip"
  layer_name          = "${var.environment}-requests-layer"
  compatible_runtimes = ["python3.9", "python3.10"]
  source_code_hash    = filebase64sha256("layers/compressed/requests-layer.zip")
}

# Layer for psycopg2
resource "aws_lambda_layer_version" "psycopg2_layer" {
  filename            = "layers/compressed/psycopg2-layer.zip"
  layer_name          = "${var.environment}-psycopg2-layer"
  compatible_runtimes = ["python3.9", "python3.10"]
  source_code_hash    = filebase64sha256("layers/compressed/psycopg2-layer.zip")
}


resource "aws_lambda_function" "media_analysis" {
  filename      = "compressed/${var.environment}-media-analysis.zip"
  function_name = "${var.environment}-media-analysis"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    variables = {
      POSTS_BUCKET         = "${var.environment}-creator-catalyst-analytics"
      POSTS_TABLE          = "SocialNetworkPosts"
      RESPONSE_WEBHOOK_URL = "https://uyy2v7yn1c.execute-api.us-west-1.amazonaws.com/dev/unitarywh"
      UNITARY_API_KEY      = "21be3bac-dca0-4cc2-b51a-819338a21d84"
      UNITARY_API_LOCATION = "https://api.unitary.ai/v1"
    }
  }
}

resource "aws_lambda_event_source_mapping" "media_analysis_sqs_trigger" {
  event_source_arn = aws_sqs_queue.media_processing.arn
  function_name    = aws_lambda_function.media_analysis.function_name
  batch_size       = 1
  enabled          = true
}


resource "aws_lambda_function" "metrics" {
  filename      = "compressed/${var.environment}-metrics.zip"
  function_name = "${var.environment}-metrics"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    variables = {
      ATHENA_DATABASE = "${var.environment}-creator-catalyst-athena-database"
      S3_BUCKET       = aws_s3_bucket.creator_catalyst_analytics.bucket
      S3_FOLDER       = "metrics"
      SECRET_NAME     = "${var.environment}/backend/docker"
    }
  }

  layers = [
    aws_lambda_layer_version.psycopg2_layer.arn
  ]
}

resource "aws_lambda_function" "post_batch_processing" {
  filename      = "compressed/${var.environment}-posts-batch-processing.zip"
  function_name = "${var.environment}-post-batch-processing"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  # Hay que revvisar estos datos
  environment {
    variables = {
      ATHENA_DATABASE = "${var.environment}-creator-catalyst-athena-database"
      S3_BUCKET       = aws_s3_bucket.creator_catalyst_analytics.bucket
      S3_FOLDER       = "post-batch-processing"
      SECRET_NAME     = "${var.environment}/backend/docker"
      POSTS_TABLE     = "postmetrics"
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn
  ]
}

resource "aws_lambda_function" "posts_score_metrics" {
  filename      = "compressed/${var.environment}-posts-score-metrics.zip"
  function_name = "${var.environment}-posts-score-metrics"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    variables = {
      S3_BUCKET   = aws_s3_bucket.creator_catalyst_analytics.bucket
      S3_FOLDER   = "metrics"
      SECRET_NAME = "${var.environment}/backend/docker"
    }
  }
}

resource "aws_lambda_function" "posts_processing" {
  filename      = "compressed/${var.environment}-posts-processing.zip"
  function_name = "${var.environment}-posts-processing"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  # Hay que revvisar estos datos
  environment {
    variables = {
      ATHENA_DATABASE = "${var.environment}-creator-catalyst-athena-database"
      S3_BUCKET       = aws_s3_bucket.creator_catalyst_analytics.bucket
      S3_FOLDER       = "post-batch-processing"
      SECRET_NAME     = "${var.environment}/backend/docker"
      POSTS_TABLE     = "postmetrics"
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn
  ]
}

resource "aws_lambda_function" "process_report_batch" {
  filename      = "compressed/${var.environment}-process-report-batch.zip"
  function_name = "${var.environment}-process-report-batch"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  # Revisar estas variables
  environment {
    variables = {
      API_PASSWORD          = "zIiwiZXhwIjoxNzEyOTU"
      API_URL               = "https://apidev.creatorcatalyst.ai"
      API_USER              = "autoupdater@momofactor.com"
      ATHENA_DB             = "${var.environment}-creatorcatalyst-athena-database"
      ATHENA_RESULTS_BUCKET = aws_s3_bucket.creator_catalyst_analytics.bucket
      SCRAPER_SQS           = aws_sqs_queue.creator_catalyst_queue_cc.arn
      USER_METRICS_BUCKET   = "usermetrics-posts-creator-catalyst"
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn
  ]
}

resource "aws_lambda_event_source_mapping" "report_batches_sqs_trigger" {
  event_source_arn = aws_sqs_queue.report_batches.arn
  function_name    = aws_lambda_function.process_report_batch.function_name
  batch_size       = 1
  enabled          = true
}

resource "aws_lambda_function" "score_metrics" {
  filename      = "compressed/${var.environment}-score-metrics.zip"
  function_name = "${var.environment}-score-metrics"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  # Revisar estas variables
  environment {
    variables = {
      ATHENA_DB          = "${var.environment}-creatorcatalyst-athena-database"
      BACKUP_LOCATION    = "score_metrics"
      DESTINATION_BUCKET = aws_s3_bucket.creator_catalyst_analytics.bucket
      FILETYPE           = "parquet"
      GLUE_JOB_NAME      = "convert_file"
      QUERY_RESULTS_PATH = "score_metrics"
      SOURCE_BUCKET      = aws_s3_bucket.creator_catalyst_analytics.bucket
    }
  }
}

resource "aws_lambda_function" "unitary_webhook" {
  filename      = "compressed/${var.environment}-unitary-webhook.zip"
  function_name = "${var.environment}-unitary-webhook"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  # Revisar estas variables
  environment {
    variables = {
      POSTS_BUCKET = "data-creator-catalyst"
      POSTS_TABLE  = "SocialNetworkPosts"
      TAGS_BUCKET  = "tags-creator-catalyst"
    }
  }
}

resource "aws_lambda_function" "process_creator_report" {
  filename      = "compressed/${var.environment}-process-creator-report.zip"
  function_name = "${var.environment}-process-creator-report"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    variables = {
      REPORT_BATCH_SQS = aws_sqs_queue.report_batches.arn
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn
  ]
}
# Function for sending emails

resource "aws_lambda_function" "send_email" {
  filename      = "compressed/${var.environment}-send_email.zip"
  function_name = "${var.environment}-send_email"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  role          = data.aws_iam_role.lambda_role.arn

  environment {
    variables = {
      SECRET_NAME     = "${var.environment}/backend/docker"
      DOMAIN_NAME     = "cc.creatorcatalyst.ai"
    }
  }

  layers = [
    aws_lambda_layer_version.requests_layer.arn,
    aws_lambda_layer_version.boto3_layer.arn
  ]
}

resource "aws_lambda_event_source_mapping" "send_email_sqs_trigger" {
  event_source_arn = aws_sqs_queue.send_email_queue.arn
  function_name    = aws_lambda_function.send_email.function_name
  batch_size       = 1
  enabled          = true
}
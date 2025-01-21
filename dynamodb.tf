resource "aws_dynamodb_table" "creators_results" {
  name         = "${var.environment}-creators-results"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "result_uuid"
  range_key = "platform_username"

  attribute {
    name = "result_uuid"
    type = "S"
  }

  attribute {
    name = "platform_username"
    type = "S"
  }

  attribute {
    name = "match"
    type = "N"
  }

  global_secondary_index {
    name               = "MatchIndex"
    hash_key           = "result_uuid"
    range_key          = "match"
    projection_type    = "ALL"
    read_capacity      = 0
    write_capacity     = 0
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

resource "aws_dynamodb_table" "openai_threads" {
  name         = "${var.environment}-openai-threads"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "thread_id"
  range_key = "created_at"

  attribute {
    name = "thread_id"
    type = "S"
  }

  attribute {
    name = "created_at"
    type = "S"
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

resource "aws_dynamodb_table" "metrics_results" {
  name         = "${var.environment}-metrics-results"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

resource "aws_dynamodb_table" "phrases_store" {
  name         = "${var.environment}-phrases-store"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "model_id"
  range_key = "phrase_id"

  attribute {
    name = "model_id"
    type = "S"
  }

  attribute {
    name = "phrase_id"
    type = "S"
  }

  attribute {
    name = "date_timestamp"
    type = "N"
  }

  global_secondary_index {
    name               = "date_timestamp-index"
    hash_key           = "date_timestamp"
    projection_type    = "ALL"
    read_capacity      = 0
    write_capacity     = 0
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

resource "aws_dynamodb_table" "scrapers_result" {
  name         = "${var.environment}-scrapers-result"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

resource "aws_dynamodb_table" "social_network_posts" {
  name         = "${var.environment}-social-network-posts"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "post_id"

  attribute {
    name = "post_id"
    type = "S"
  }

  table_class = "STANDARD"

  tags = {
    Environment = var.environment
  }

  deletion_protection_enabled = false
}

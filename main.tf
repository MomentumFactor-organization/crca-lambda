terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
}

provider "aws" {
  region = "us-west-1"
}

variable "environment" {
  description = "The environment for the deployment (e.g. develop, staging, production)"
  type        = string
}

# Data
data "aws_iam_role" "glue_role" {
  name = "AWSGlueServiceRole"
}

data "aws_iam_role" "lambda_role" {
  name = "${var.environment}-lambda-role"
}

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

# Outputs to use the ARNs of the layers in functions
output "boto3_layer_arn" {
  value = aws_lambda_layer_version.boto3_layer.arn
}

output "requests_layer_arn" {
  value = aws_lambda_layer_version.requests_layer.arn
}

output "psycopg2_layer_arn" {
  value = aws_lambda_layer_version.psycopg2_layer.arn
}

# S3
resource "aws_s3_bucket" "creator_catalyst_analytics" {
  bucket = "${var.environment}-creator-catalyst-analytics"
  tags = {
    environment = var.environment
  }
}

# SQS
resource "aws_sqs_queue" "creator_catalyst_queue_cc" {
  name = "${var.environment}-dev-queue-cc"
}

resource "aws_sqs_queue" "creator_catalyst_post_processing" {
  name = "${var.environment}-post-processing"
}

# Glue
resource "aws_glue_catalog_database" "creator_catalyst" {
  name = "${var.environment}-creator-catalyst-athena-database"
}

# Glue Crawler
resource "aws_glue_crawler" "posts_metrics" {
  name          = "${var.environment}-posts-metrics-crawler"
  role          = "AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = ""
  table_prefix  = ""
  s3_target {
    path = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/metrics/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = {
    "environment" = var.environment
  }
}
resource "aws_glue_crawler" "posts_data" {
  name          = "${var.environment}-posts-data-crawler"
  role          = "AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = ""
  table_prefix  = ""
  s3_target {
    path = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/posts/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = {
    "environment" = var.environment
  }
}

resource "aws_glue_crawler" "tags_metrics" {
  name          = "${var.environment}-tags-metrics-crawler"
  role          = "AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.creator_catalyst.name

  s3_target {
    path = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/tags/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_glue_crawler" "post_score_metrics" {
  name          = "${var.environment}-post-score-metrics-crawler"
  role          = "AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.creator_catalyst.name

  s3_target {
    path = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/score_metrics/score_metrics/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }

  tags = {
    environment = var.environment
  }
}

resource "aws_glue_crawler" "post_score_avg_metrics" {
  name          = "${var.environment}-post-score-avg-metrics-crawler"
  role          = "AWSGlueServiceRole"
  database_name = aws_glue_catalog_database.creator_catalyst.name

  s3_target {
    path = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/score_metrics/score_avg_metrics/"
  }

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "DEPRECATE_IN_DATABASE"
  }
  tags = {
    environment = var.environment
  }
}


# Glue tables
resource "aws_glue_catalog_table" "metrics" {
  name          = "${var.environment}-metrics"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = "Creator Metrics Table for Analytics"

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location          = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/metrics/"
    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed        = false
    number_of_buckets = -1

    columns {
      name = "comments"
      type = "int"
    }

    columns {
      name = "likes"
      type = "int"
    }

    columns {
      name = "video_views"
      type = "int"
    }

    columns {
      name = "video_plays"
      type = "int"
    }

    columns {
      name = "platform"
      type = "string"
    }

    columns {
      name = "username"
      type = "string"
    }

    columns {
      name = "post_id"
      type = "string"
    }

    ser_de_info {
      name = "org.openx.data.jsonserde.JsonSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  partition_keys {
    name = "post_id"
    type = "string"
  }

  parameters = {
    "classification"     = "json"
    "UPDATED_BY_CRAWLER" = "{var.environment}-posts-metrics-crawler"
  }
}

resource "aws_glue_catalog_table" "posts" {
  name          = "${var.environment}-posts"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = "Table of creator posts"

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location          = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/posts/"
    input_format      = "org.apache.hadoop.mapred.TextInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed        = false
    number_of_buckets = -1

    columns {
      name = "caption"
      type = "string"
    }

    columns {
      name = "comments"
      type = "int"
    }

    columns {
      name = "creator_user"
      type = "string"
    }

    columns {
      name = "date"
      type = "string"
    }

    columns {
      name = "likes"
      type = "int"
    }

    columns {
      name = "media"
      type = "array<struct<photo_url:string,s3_url:string,video_url:string>>"
    }

    columns {
      name = "original_url"
      type = "string"
    }

    columns {
      name = "platform_id"
      type = "string"
    }

    columns {
      name = "video_plays"
      type = "int"
    }

    columns {
      name = "video_views"
      type = "int"
    }

    columns {
      name = "snapshot"
      type = "string"
    }

    columns {
      name = "platform"
      type = "string"
    }

    columns {
      name = "username"
      type = "string"
    }

    columns {
      name = "post_id"
      type = "string"
    }

    ser_de_info {
      name = "org.openx.data.jsonserde.JsonSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  partition_keys {
    name = "post_id"
    type = "string"
  }

  parameters = {
    "classification"     = "json"
    "UPDATED_BY_CRAWLER" = "${var.environment}-posts-data-crawler"
  }
}

resource "aws_glue_catalog_table" "score_avg_metrics" {
  name          = "${var.environment}-score-avg-metrics"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = "Table of averages of scoring metrics"

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location          = "s3://athena-results-creator-catalyst/score_metrics/score_avg_metrics/"
    input_format      = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed        = false
    number_of_buckets = -1

    columns {
      name = "platform"
      type = "string"
    }

    columns {
      name = "username"
      type = "string"
    }

    columns {
      name = "violence_score"
      type = "string"
    }

    columns {
      name = "violence_firearm_score"
      type = "string"
    }

    columns {
      name = "violence_knife_score"
      type = "string"
    }

    columns {
      name = "violence_violent_knife_score"
      type = "string"
    }

    columns {
      name = "substances_alcohol_score"
      type = "string"
    }

    columns {
      name = "substances_drink_score"
      type = "string"
    }

    columns {
      name = "substances_smoking_and_tobacco_score"
      type = "string"
    }

    columns {
      name = "substances_marijuana_score"
      type = "string"
    }

    columns {
      name = "substances_pills_score"
      type = "string"
    }

    columns {
      name = "substances_recreational_pills_score"
      type = "string"
    }

    columns {
      name = "nsfw_adult_content_score"
      type = "string"
    }

    columns {
      name = "nsfw_suggestive_score"
      type = "string"
    }

    columns {
      name = "nsfw_adult_toys_score"
      type = "string"
    }

    columns {
      name = "nsfw_medical_score"
      type = "string"
    }

    columns {
      name = "nsfw_over_18_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_anus_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_armpits_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_belly_score"
      type = "string"
    }

    columns {
      name = "nsfw_covered_belly_score"
      type = "string"
    }

    columns {
      name = "nsfw_covered_buttocks_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_buttocks_score"
      type = "string"
    }

    columns {
      name = "nsfw_covered_feet_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_feet_score"
      type = "string"
    }

    columns {
      name = "nsfw_covered_breast_f_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_breast_f_score"
      type = "string"
    }

    columns {
      name = "nsfw_covered_genitalia_f_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_genitalia_f_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_breast_m_score"
      type = "string"
    }

    columns {
      name = "nsfw_exposed_genitalia_m_score"
      type = "string"
    }

    columns {
      name = "hate_symbols_confederate_flag_score"
      type = "string"
    }

    columns {
      name = "hate_symbols_pepe_frog_score"
      type = "string"
    }

    columns {
      name = "hate_symbols_nazi_swastika_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_toxicity_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_severe_toxicity_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_obscene_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_insult_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_identity_attack_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_threat_score"
      type = "string"
    }

    columns {
      name = "ocr_language_toxicity_sexual_explicit_score"
      type = "string"
    }

    columns {
      name = "visual_content_artistic_score"
      type = "string"
    }

    columns {
      name = "visual_content_comic_score"
      type = "string"
    }

    columns {
      name = "visual_content_meme_score"
      type = "string"
    }

    columns {
      name = "visual_content_screenshot_score"
      type = "string"
    }

    columns {
      name = "visual_content_map_score"
      type = "string"
    }

    columns {
      name = "visual_content_poster_cover_score"
      type = "string"
    }

    columns {
      name = "visual_content_game_screenshot_score"
      type = "string"
    }

    columns {
      name = "visual_content_face_filter_score"
      type = "string"
    }

    columns {
      name = "visual_content_promo_info_graphic_score"
      type = "string"
    }

    columns {
      name = "visual_content_photo_score"
      type = "string"
    }

    columns {
      name = "other_child_score"
      type = "string"
    }

    columns {
      name = "other_middle_finger_gesture_score"
      type = "string"
    }

    columns {
      name = "other_toy_score"
      type = "string"
    }

    columns {
      name = "other_gambling_machine_score"
      type = "string"
    }

    columns {
      name = "other_face_f_score"
      type = "string"
    }

    columns {
      name = "other_face_m_score"
      type = "string"
    }

    ser_de_info {
      name = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  parameters = {
    "classification"     = "parquet"
    "UPDATED_BY_CRAWLER" = "${var.environment}-post-score-avg-metrics-crawler"
  }
}

resource "aws_glue_catalog_table" "score_metrics" {
  name          = "${var.environment}-score-metrics"
  database_name = aws_glue_catalog_database.creatorsdb.name
  description   = "Scoring Metrics Table"

  table_type = "EXTERNAL_TABLE"

  storage_descriptor {
    location          = "s3://athena-results-creator-catalyst/score_metrics/score_metrics/"
    input_format      = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format     = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    compressed        = false
    number_of_buckets = -1

    columns {
      name = "f1_nsfw_covered_buttocks_risk"
      type = "string"
    }

    columns {
      name = "f1_nsfw_exposed_buttocks_risk"
      type = "string"
    }

    columns {
      name = "f1_nsfw_covered_feet_risk"
      type = "string"
    }

    columns {
      name = "f1_nsfw_exposed_feet_risk"
      type = "string"
    }

    columns {
      name = "f1_hate_symbols_confederate_flag_risk"
      type = "string"
    }

    columns {
      name = "f1_hate_symbols_pepe_frog_risk"
      type = "string"
    }

    columns {
      name = "f1_hate_symbols_nazi_swastika_risk"
      type = "string"
    }

    columns {
      name = "f1_other_child_risk"
      type = "string"
    }

    columns {
      name = "f1_other_toy_risk"
      type = "string"
    }

    columns {
      name = "f1_other_face_f_risk"
      type = "string"
    }

    columns {
      name = "f1_other_face_m_risk"
      type = "string"
    }

    columns {
      name = "f1_other_glass_risk"
      type = "string"
    }

    columns {
      name = "f1_other_pillow_risk"
      type = "string"
    }

    columns {
      name = "f1_other_bottle_risk"
      type = "string"
    }

    columns {
      name = "f1_other_plate_risk"
      type = "string"
    }

    columns {
      name = "f1_other_pet_risk"
      type = "string"
    }

    columns {
      name = "f1_other_person_risk"
      type = "string"
    }

    columns {
      name = "f1_other_logo_risk"
      type = "string"
    }

    columns {
      name = "f1_nsfw_generic_risk"
      type = "string"
    }

    ser_de_info {
      name = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  parameters = {
    "classification"     = "parquet"
    "UPDATED_BY_CRAWLER" = "${var.environment}-post-score-metrics-crawler"
  }
}

resource "aws_glue_catalog_table" "tags" {
  name          = "${var.environment}-tags"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = "Tag table for content analysis"

  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/tags/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = false
    number_of_buckets = -1

    columns {
      name = "violence"
      type = "struct<violence:double,firearm:double,knife:double,violent_knife:double>"
    }

    columns {
      name = "substances"
      type = "struct<alcohol:double,drink:double,smoking_and_tobacco:double,marijuana:double,pills:double,recreational_pills:double>"
    }

    columns {
      name = "nsfw"
      type = "struct<adult_content:double,suggestive:double,adult_toys:double,medical:double,over_18:double,exposed_anus:double,exposed_armpits:double,exposed_belly:double,covered_belly:double,covered_buttocks:double,exposed_buttocks:double,covered_feet:double,exposed_feet:double,covered_breast_f:double,exposed_breast_f:double,covered_genitalia_f:double,exposed_genitalia_f:double,exposed_breast_m:double,exposed_genitalia_m:double>"
    }

    columns {
      name = "hate_symbols"
      type = "struct<confederate_flag:double,pepe_frog:double,nazi_swastika:double>"
    }

    columns {
      name = "ocr_language_toxicity"
      type = "struct<toxicity:double,severe_toxicity:double,obscene:double,insult:double,identity_attack:double,threat:double,sexual_explicit:double>"
    }

    columns {
      name = "visual_content"
      type = "struct<artistic:double,comic:double,meme:double,screenshot:double,map:double,poster_cover:double,game_screenshot:double,face_filter:double,promo_info_graphic:double,photo:double>"
    }

    columns {
      name = "other"
      type = "struct<child:double,middle_finger_gesture:double,toy:double,gambling_machine:double,face_f:double,face_m:double>"
    }

    columns {
      name = "url"
      type = "string"
    }

    columns {
      name = "audio_language_toxicity"
      type = "struct<toxicity:double,severe_toxicity:double,obscene:double,insult:double,identity_attack:double,threat:double,sexual_explicit:double>"
    }

    columns {
      name = "metadata"
      type = "struct<width:int,height:int,fps:double,duration:double,seconds_processed:double>"
    }

    columns {
      name = "platform"
      type = "string"
    }

    columns {
      name = "username"
      type = "string"
    }

    columns {
      name = "post_id"
      type = "string"
    }

    columns {
      name = "vendor"
      type = "string"
    }

    columns {
      name = "media_id"
      type = "string"
    }

    ser_de_info {
      name = "org.openx.data.jsonserde.JsonSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  partition_keys {
    name = "post_id"
    type = "string"
  }

  partition_keys {
    name = "vendor"
    type = "string"
  }

  partition_keys {
    name = "media_id"
    type = "string"
  }

  parameters = {
    "classification"    = "json"
    "UPDATED_BY_CRAWLER" = "${var.environment}-tags-metrics-crawler"
  }
}

resource "aws_glue_catalog_table" "user_metrics" {
  name          = "${var.environment}-user-metrics"
  database_name = aws_glue_catalog_database.creator_catalyst.name
  description   = "User Metrics Table for Analysis"

  table_type    = "EXTERNAL_TABLE"

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/users/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    compressed    = false
    number_of_buckets = -1

    columns {
      name = "comments"
      type = "int"
    }

    columns {
      name = "likes"
      type = "int"
    }

    columns {
      name = "video_views"
      type = "int"
    }

    columns {
      name = "video_plays"
      type = "int"
    }

    columns {
      name = "platform"
      type = "string"
    }

    columns {
      name = "username"
      type = "string"
    }

    ser_de_info {
      name = "org.openx.data.jsonserde.JsonSerDe"
    }
  }

  partition_keys {
    name = "platform"
    type = "string"
  }

  partition_keys {
    name = "username"
    type = "string"
  }

  parameters = {
    "classification"   = "json"
    "UpdatedByJob"     = "Test"
  }
}


# Glue Scripts

resource "aws_glue_job" "creator_catalyst_convert_file" {
  name     = "${var.environment}-creator-catalyst-convert-file"
  role_arn = data.aws_iam_role.glue_role.arn

  command {
    name            = "glueetl" # Glue Spark ETL
    script_location = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/scripts/convert_file.py"
    python_version  = "3"
  }
  default_arguments = {
    "--TempDir"             = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/temp/"
    "--job-bookmark-option" = "job-bookmark-enable"
    "--enable-metrics"      = ""
    "--environment"         = var.environment
  }
  glue_version      = "3.0"
  worker_type       = "G.1X"
  number_of_workers = 2
  max_retries       = 1
  timeout           = 60
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.creator_catalyst_analytics.bucket
  key    = "scripts/convert_file.py"
  source = "scripts/convert_file.py"
}

# Athena
resource "aws_athena_workgroup" "creator_workgroup" {
  name = "${var.environment}-creator-workgroup"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.creator_catalyst_analytics.bucket}/"
    }
  }
}

# Lambdas
resource "aws_sqs_queue" "media_processing" {
  name = "${var.environment}-media-processing"
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

#

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

#

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

#

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

#

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

#

resource "aws_sqs_queue" "report_batches" {
  name = "${var.environment}-report-batches"
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
      API_URL               = "https://apidev.creatorcatalyst.ai"
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

#

resource "aws_sqs_queue" "metrics_reporting" {
  name = "${var.environment}-metrics-reporting"
}

#

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

#

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

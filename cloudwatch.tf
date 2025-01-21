resource "aws_cloudwatch_dashboard" "creator_catalyst_dashboard" {
  dashboard_name = "${var.environment}-creator-catalyst-dashboard"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 6,
        "y" : 1,
        "x" : 12,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.posts_processing.function_name}", ],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Posts Processing ",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 8,
        "y" : 7,
        "x" : 8,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.unitary_webhook.function_name}", { "color" : "#08aad2" }],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Unitary Webhook Response",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 8,
        "y" : 7,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.media_analysis.function_name}", { "color" : "#08aad2" }],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Media Processing",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 1,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", "${aws_lambda_function.process_creator_report.function_name}", { "color" : "#dfb52c" }],
            [".", "Invocations", ".", ".", { "color" : "#08aad2" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Report Processing ",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 8,
        "y" : 7,
        "x" : 16,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.metrics.function_name}"],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : true,
          "title" : "Metrics Report",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 1,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.process_report_batch.function_name}"],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Report Processing - Batch",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 1,
        "x" : 18,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "${aws_lambda_function.post_batch_processing.function_name}"],
            [".", "Errors", ".", ".", { "color" : "#fe6e73" }],
            [".", "ConcurrentExecutions", ".", ".", { "color" : "#dfb52c" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "title" : "Posts Processing - Batch",
          "period" : 60,
          "stat" : "Average"
        }
      },
      {
        "height" : 1,
        "width" : 12,
        "y" : 0,
        "x" : 0,
        "type" : "text",
        "properties" : {
          "markdown" : "# Report Processing ",
          "background" : "transparent"
        }
      },
      {
        "height" : 1,
        "width" : 12,
        "y" : 0,
        "x" : 12,
        "type" : "text",
        "properties" : {
          "markdown" : "# Post Processing",
          "background" : "transparent"
        }
      }
    ]
  })
}

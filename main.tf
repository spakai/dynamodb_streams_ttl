# Create a DynamoDB table to store the scheduled tasks with attributes for task ID and scheduled time , Set up a TTL for the scheduled_time attribute, 
//and enable streams on the table.

resource "aws_dynamodb_table" "cron_job" {
  name         = "scheduled_tasks"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "task_id"
    type = "S"
  }

  attribute {
    name = "scheduled_time"
    type = "N"
  }

  hash_key = "task_id"

  stream_enabled   = true
  stream_view_type = "OLD_IMAGE"

  ttl {
    attribute_name = "scheduled_time"
    enabled        = true
  }

   global_secondary_index {
    name            = "scheduled_time_index"
    hash_key        = "scheduled_time"
    projection_type = "ALL"
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

// Create a policy that allows the Lambda function to interact with DynamoDB and CloudWatch Logs.
resource "aws_iam_policy" "lambda_policy" {
  name        = "lambda_dynamodb_policy"
  description = "Policy for Lambda to interact with DynamoDB and CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:Query",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:PutItem",
          "dynamodb:Scan"
        ],
        Resource = [
          aws_dynamodb_table.cron_job.arn,
          "${aws_dynamodb_table.cron_job.arn}/stream/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

// Attach the policy to the role.
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_policy.arn
  role       = aws_iam_role.lambda_role.name
}

resource "aws_lambda_function" "task_processor" {
  function_name = "process_overdue_tasks"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_role.arn

  filename         = "./lambda.zip" # Path to your packaged Lambda function
  source_code_hash = filebase64sha256("lambda.zip")

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.cron_job.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "dynamodb_stream" {
  event_source_arn = aws_dynamodb_table.cron_job.stream_arn
  function_name    = aws_lambda_function.task_processor.arn
  starting_position = "LATEST"
}
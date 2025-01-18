// print all arns
output "dynamodb_stream_arns" {
  value = aws_dynamodb_table.cron_job.arn
}

output "lambda_function_arn" {
  value = aws_lambda_function.task_processor.arn
}

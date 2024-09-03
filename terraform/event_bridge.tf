# EventBridge rule to trigger Lambda every hour
resource "aws_cloudwatch_event_rule" "hourly_trigger" {
  name                = "hourly-trigger"
  description         = "Trigger Lambda refresh_token function every hour"
  schedule_expression = "rate(1 hour)"
}

# Permission to allow EventBridge to invoke Lambda
resource "aws_lambda_permission" "allow_eventbridge_to_invoke_lambda" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.refresh_token_spotify.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly_trigger.arn
}

# Target to link the EventBridge Rule to the Lambda Function
resource "aws_cloudwatch_event_target" "trigger_lambda" {
  rule      = aws_cloudwatch_event_rule.hourly_trigger.name
  target_id = "MyLambdaTarget"
  arn       = aws_lambda_function.refresh_token_spotify.arn
}
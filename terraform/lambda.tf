locals {
  transform_lambdas = {
    health = { function_name = aws_lambda_function.transform_health_data.function_name }
  }
  store_lambdas = {
    health = { function_name = aws_lambda_function.store_health_data.function_name },
    spotify = { function_name = aws_lambda_function.store_spotify_data.function_name }
  }
}

### Functions ###
# Store health data
resource "aws_lambda_function" "store_health_data" {
  filename                       = "../${path.module}/src/zips/store_health_data.zip"
  function_name                  = "store_health_data"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda.lambda_handler"
  runtime                        = "python3.11"
  timeout                        = 900
  memory_size                    = 256
  depends_on                     = [aws_iam_role_policy_attachment.lambda_basic_policy_attachment]
}

# Store Spotify data
resource "aws_lambda_function" "store_spotify_data" {
  filename                       = "../${path.module}/src/zips/store_spotify_data.zip"
  function_name                  = "store_spotify_data"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda.lambda_handler"
  runtime                        = "python3.11"
  timeout                        = 900
  memory_size                    = 256
  depends_on                     = [aws_iam_role_policy_attachment.lambda_basic_policy_attachment]
}

# Transform health data
resource "aws_lambda_function" "transform_health_data" {
  filename                       = "../${path.module}/src/zips/transform_health_data.zip"
  function_name                  = "transform_health_data"
  role                           = aws_iam_role.lambda_role.arn
  handler                        = "lambda.lambda_handler"
  runtime                        = "python3.11"
  timeout                        = 900
  memory_size                    = 256
  depends_on                     = [
    aws_iam_role_policy_attachment.lambda_basic_policy_attachment,
    aws_iam_role_policy_attachment.lambda_s3_policy_attachment]
}

# Lambda permissions
resource "aws_lambda_permission" "allow_apigw" {
  for_each = local.store_lambdas

  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_metricnier.execution_arn}/*"
}

# S3 permissions
resource "aws_lambda_permission" "allow_s3_invoke" {
  for_each = local.transform_lambdas

  statement_id  = "allow-s3-invoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.s3_bucket.id}"
}
resource "aws_lambda_function" "store_health_data" {
filename                       = "../${path.module}/src/zips/store_health_data.zip"
function_name                  = "store_health_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "lambda.lambda_handler"
runtime                        = "python3.11"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# Store Spotify data
resource "aws_lambda_function" "store_spotify_data" {
filename                       = "../${path.module}/src/zips/store_spotify_data.zip"
function_name                  = "store_spotify_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "lambda.lambda_handler"
runtime                        = "python3.11"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

# Lambda permissions
resource "aws_lambda_permission" "apigw_lambda_health" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_health_data.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_metricnier.execution_arn}/*"
}

resource "aws_lambda_permission" "apigw_lambda_spotify" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_spotify_data.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_metricnier.execution_arn}/*"
}
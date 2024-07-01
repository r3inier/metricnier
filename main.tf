# Lambda Function

provider "aws" {
  region = "ap-southeast-2"
}

resource "aws_iam_role" "lambda_role" {
name   = "Lambda_Role"
assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_func" {
filename                       = "${path.module}/python/zips/hello-python.zip"
function_name                  = "health_export"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.11"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

########################################################################################
# API Gateway

resource "aws_api_gateway_api_key" "api_key" {
  name        = "metricnier_api_key"
  description = "Metricnier API Key"
  enabled     = true
}

resource "aws_api_gateway_usage_plan" "usage_key" {
  name = "metricnier_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_metricnier.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_usage_plan_key" "api_key_plan" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_key.id
}

resource "aws_api_gateway_rest_api" "api_metricnier" {
  name = "api_metricnier"
  description = "API for Metricnier"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "root" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  parent_id = aws_api_gateway_rest_api.api_metricnier.root_resource_id
  path_part = "health-export"
}

resource "aws_api_gateway_method" "health_export_method" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = "ANY"
  authorization = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.header.x-api-key" = true
  }
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.health_export_method.http_method
  integration_http_method = "ANY"
  type = "AWS"
  uri = aws_lambda_function.lambda_func.invoke_arn
}

resource "aws_api_gateway_method_response" "health_export_method" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.health_export_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "health_export_method" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.root.id
  http_method = aws_api_gateway_method.health_export_method.http_method
  status_code = aws_api_gateway_method_response.health_export_method.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.health_export_method,
    aws_api_gateway_integration.lambda_integration
  ]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_metricnier.id
  stage_name    = "default"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_func.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_metricnier.execution_arn}/*"
}

########################################################################################
# Data Sources
data "archive_file" "lambda_package" {
  type = "zip"
  source_file = "python/lambdas/hello-python/index.py"
  output_path = "python/zips/hello-python.zip"
}
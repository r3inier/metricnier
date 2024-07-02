provider "aws" {
  region = "ap-southeast-2"
}

# Creating IAM role 
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

resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda-s3-policy"
  description = "IAM policy for Lambda to access S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:DeleteBucket"
        ]
        Effect = "Allow"
        Resource = "${aws_s3_bucket.s3_bucket.arn}/*"
      }
    ]
  })
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.store_health_data.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api_metricnier.execution_arn}/*"
}

# Policy attachments
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
 role        = aws_iam_role.lambda_role.name
 policy_arn  = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

################################################################################################################################################################################
# Lambda functions
# 
resource "aws_lambda_function" "store_health_data" {
filename                       = "${path.module}/python/zips/store_health_data.zip"
function_name                  = "store_health_data"
role                           = aws_iam_role.lambda_role.arn
handler                        = "index.lambda_handler"
runtime                        = "python3.11"
depends_on                     = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}

################################################################################################################################################################################
# Creating API key
resource "aws_api_gateway_api_key" "api_key" {
  name        = "metricnier_api_key"
  description = "Metricnier API Key"
  enabled     = true
}

# Creating usage plan
resource "aws_api_gateway_usage_plan" "usage_key" {
  name = "metricnier_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.api_metricnier.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

# Connecting API key and usage plan
resource "aws_api_gateway_usage_plan_key" "api_key_plan" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_key.id
}

################################################################################################################################################################################
# Creating API Gateway
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
  uri = aws_lambda_function.store_health_data.invoke_arn
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

################################################################################################################################################################################
# S3 Bucket
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "metricnier-bucket"
}

resource "aws_s3_bucket_public_access_block" "s3_bucket" {
  bucket = aws_s3_bucket.s3_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################################################################################################################
# Data Sources
data "archive_file" "lambda_package" {
  type = "zip"
  source_file = "python/lambdas/store_health_data/index.py"
  output_path = "python/zips/store_health_data.zip"
}
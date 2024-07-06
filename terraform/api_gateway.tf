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

# API & Lambda Health Integration 
resource "aws_api_gateway_resource" "ingest_health" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  parent_id = aws_api_gateway_rest_api.api_metricnier.root_resource_id
  path_part = "ingest-health"
}

resource "aws_api_gateway_method" "ingest_health" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_health.id
  http_method = "POST"
  authorization = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.header.x-api-key" = true
  }
}

resource "aws_api_gateway_method_response" "ingest_health" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_health.id
  http_method = aws_api_gateway_method.ingest_health.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }

}

resource "aws_api_gateway_integration_response" "ingest_health" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_health.id
  http_method = aws_api_gateway_method.ingest_health.http_method
  status_code = aws_api_gateway_method_response.ingest_health.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.ingest_health,
    aws_api_gateway_integration.lambda_health_integration
  ]
}

resource "aws_api_gateway_integration" "lambda_health_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_health.id
  http_method = aws_api_gateway_method.ingest_health.http_method
  integration_http_method = "POST"
  type = "AWS"
  uri = aws_lambda_function.store_health_data.invoke_arn
  passthrough_behavior = "WHEN_NO_TEMPLATES"

  request_templates = {
  "application/json" = <<EOF
{
  "body" : $input.json('$'),
  "automation-name" : "$util.escapeJavaScript($input.params().header.get('automation-name'))"
}
EOF
  }
}


# API & Lambda Spotify Integration 
resource "aws_api_gateway_resource" "ingest_spotify" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  parent_id = aws_api_gateway_rest_api.api_metricnier.root_resource_id
  path_part = "ingest-spotify"
}

resource "aws_api_gateway_method" "ingest_spotify" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_spotify.id
  http_method = "ANY"
  authorization = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.header.x-api-key" = true
  }
}

resource "aws_api_gateway_method_response" "ingest_spotify" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_spotify.id
  http_method = aws_api_gateway_method.ingest_spotify.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "ingest_spotify" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_spotify.id
  http_method = aws_api_gateway_method.ingest_spotify.http_method
  status_code = aws_api_gateway_method_response.ingest_spotify.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" =  "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.ingest_spotify,
    aws_api_gateway_integration.lambda_spotify_integration
  ]
}

resource "aws_api_gateway_integration" "lambda_spotify_integration" {
  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
  resource_id = aws_api_gateway_resource.ingest_spotify.id
  http_method = aws_api_gateway_method.ingest_spotify.http_method
  integration_http_method = "ANY"
  type = "AWS_PROXY"
  uri = aws_lambda_function.store_spotify_data.invoke_arn
}

# Creating API Gateway
resource "aws_api_gateway_rest_api" "api_metricnier" {
  name = "api_metricnier"
  description = "API for Metricnier"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Staging API Gateway
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api_metricnier.id
  stage_name    = "default"
}

# Deploying API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_health_integration,
    aws_api_gateway_integration.lambda_spotify_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api_metricnier.id
}

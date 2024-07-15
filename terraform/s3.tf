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

resource "aws_s3_bucket_notification" "trigger_health_lambdas" {
  bucket = aws_s3_bucket.s3_bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.transform_health_data.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/health"
  }
}
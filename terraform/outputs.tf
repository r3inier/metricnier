data "archive_file" "lambda_store_health_package" {
  type = "zip"
  source_file = "../src/functions/store_health_data/lambda.py"
  output_path = "../src/zips/store_health_data.zip"
}

data "archive_file" "lambda_store_spotify_package" {
  type = "zip"
  source_file = "../src/functions/store_spotify_data/lambda.py"
  output_path = "../src/zips/store_spotify_data.zip"
}

data "archive_file" "lambda_transform_health_package" {
  type = "zip"
  source_file = "../src/functions/transform_health_data/lambda.py"
  output_path = "../src/zips/transform_health_data.zip"
}
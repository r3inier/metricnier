import json
import boto3

def transform_data(data):
    # to do
    return data

def lambda_handler(event, context):
    bucket_name = "metricnier-bucket"
    input_file = event["Records"][0]["s3"]["object"]["key"]
    output_file = ""
    automation_name = input_file.replace("raw/health/", "").replace(".json", "")

    if automation_name == "health-metrics":
        output_file = "processed/health/health-metrics.json"
    elif automation_name == "workouts":
        output_file = "processed/health/workouts.json"
    else:
        return {
            'statusCode': 422,
            'body': 'Invalid automation name: ' + automation_name
        }
    
    s3 = boto3.client('s3')
    s3_object = s3.get_object(
        Bucket=bucket_name, 
        Key=input_file
    )
    data = json.loads(s3_object['Body'].read().decode('UTF-8'))
    transformed_data = transform_data(data)
    s3.put_object(
        Bucket=bucket_name,
        Body=(bytes(json.dumps(transformed_data).encode('UTF-8'))), 
        Key=output_file,
    )

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully'
   }
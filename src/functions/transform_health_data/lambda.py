from helper import add_file_to_bucket, load_file_from_bucket
from health_metrics import transform_health_metrics
from workouts import transform_workouts
import json
import boto3


def transform_data(automation_name, data):
    if automation_name == "health-metrics":
        transform_health_metrics(data)
    if automation_name == "workouts":
        transform_workouts(data)

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
    data = load_file_from_bucket(input_file)
    add_file_to_bucket(output_file, data) # remove when done testing
    transform_data(automation_name, data) 

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully'
   }


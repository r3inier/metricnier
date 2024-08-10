import json
import boto3

def lambda_handler(event, context):
    bucket_name = "metricnier-bucket"
    automation_name = event.get('automation-name', 'N/A')
    
    s3 = boto3.resource('s3')
    s3_object = ""

    if (automation_name == "Health Metrics"):
        s3_object = s3.Object(bucket_name, 'raw/health/health-metrics.json')
    elif (automation_name == "Workouts"):
        s3_object = s3.Object(bucket_name, 'raw/health/workouts.json')
    else:
        return {
            'statusCode': 400,
            'body': 'Automation name not valid',
            'automation_name': automation_name
        }
    
    s3_object.put(
        Body=(bytes(json.dumps(event).encode('UTF-8')))
    )

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully',
       'automation_name': automation_name
   }
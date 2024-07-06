import json
import boto3

def lambda_handler(event, context):
    bucket_name = "metricnier-bucket"
    automation_name = event.get('automation-name', 'X')
    
    s3 = boto3.resource('s3')
    s3_object = s3.Object(bucket_name, 'raw/health/data.json')
    s3_object.put(
        Body=(bytes(json.dumps(event).encode('UTF-8')))
    )

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully',
       'automation-name': automation_name
   }
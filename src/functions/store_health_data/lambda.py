import json
import boto3

def lambda_handler(event, context):
    bucket_name = "metricnier-bucket"
    
    s3 = boto3.resource('s3')
    s3_object = s3.Object(bucket_name, 'test-name.json')
    s3_object.put(
        Body=(bytes(json.dumps(event).encode('UTF-8')))
    )

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully'
   }
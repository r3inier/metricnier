import json
import boto3

def lambda_handler(event, context):
    # TO DO:
    # - store session data into S3 (initial storage)

    return {
       'statusCode' : 200,
       'body': 'Authorisation successful'
   }
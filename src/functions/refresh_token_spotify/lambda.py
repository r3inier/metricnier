import json
import boto3

def lambda_handler(event, context):
    # TO DO:
    # - schedule to run hourly
    # - store new refresh token in S3

    return {
       'statusCode' : 200,
       'body': 'Token successfully refreshed'
   }
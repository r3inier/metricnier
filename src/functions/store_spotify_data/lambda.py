import json
import boto3

def lambda_handler(event, context):
    # TO DO:
    # - grab session data from S3
    # - token checker function that triggers refresh token if token is going to expire in 5 mins or less
    # - store data

    return {
       'statusCode' : 200,
       'body': 'Data uploaded successfully'
   }
import json
import boto3

def lambda_handler(event, context):
    # TO DO:
    # - create Spotify client
    # - store session data into S3

    return {
       'statusCode' : 200,
       'body': 'Authorisation successful'
   }
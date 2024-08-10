import json
import boto3

def lambda_handler(event, context):
    bucket_name = event.get('bucket-name', 'N/A')
    access_token = event.get('access-token', 'N/A')
    refresh_token = event.get('refresh-token', 'N/A')
    client_id = event.get('client-id', 'N/A')
    client_secret = event.get('client-secret', 'N/A')
    redirect_uri = event.get('redirect-uri', 'N/A')

    s3 = boto3.resource('s3')
    s3_object = s3.Object(bucket_name, 'spotify/auth_credentials.json')

    credentials = {
        "client_id": client_id,
        "client_secret": client_secret,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "redirect_uri": redirect_uri
    }
    
    s3_object.put(
        Body=(bytes(json.dumps(credentials).encode('UTF-8')))
    )

    return {
       'statusCode' : 200,
       'body': 'Successfully stored credentials'
   }
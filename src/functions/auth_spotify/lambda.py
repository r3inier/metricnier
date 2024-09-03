import json
import boto3
import spotipy
from spotipy.oauth2 import SpotifyOAuth

def lambda_handler(event, context):
    bucket_name = event.get('bucket-name', 'N/A')
    access_token = event.get('access-token', 'N/A')
    refresh_token = event.get('refresh-token', 'N/A')
    client_id = event.get('client-id', 'N/A')
    client_secret = event.get('client-secret', 'N/A')
    redirect_uri = event.get('redirect-uri', 'N/A')

    if bucket_name == 'N/A':
        return {
           'status_code' : 400,
           'body': 'Invalid bucket name'
        }

    s3 = boto3.resource('s3')
    s3_object = s3.Object(bucket_name, 'spotify/auth_credentials.json')

    credentials = {
        "client_id": client_id,
        "client_secret": client_secret,
        "access_token": access_token,
        "refresh_token": refresh_token,
        "redirect_uri": redirect_uri
    }
    
    auth_manager=SpotifyOAuth(client_id=client_id,
                               client_secret=client_secret,
                               redirect_uri=redirect_uri,
                               scope="user-library-read")
    
    sp = spotipy.Spotify(auth_manager=auth_manager, auth=access_token)

    # Test if authorization worked by fetching the current user's profile
    result = False
    try:
        user_profile = sp.current_user()
        result = True
    except Exception as e:
        return {
           'status_code' : 401,
           'body': f'User credentials invalid and credentials not stored. Error has been raised: {e}'
        }
    
    if result == True:
        s3_object.put(
        Body=(bytes(json.dumps(credentials).encode('UTF-8')))
        )
        
        return {
           'status_code' : 200,
           'body': 'Successfully stored and tested credentials using sp.current_user()',
           'user_profile_test': user_profile
        }
        
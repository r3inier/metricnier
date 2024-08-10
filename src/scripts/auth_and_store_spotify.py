import spotipy
import requests
import os
import pathlib
from dotenv import load_dotenv
from spotipy.oauth2 import SpotifyOAuth

# Load global variables from respective ".env folder"
main_dir = pathlib.Path(__file__).parent.parent.parent
env_path = main_dir / '.env'
load_dotenv(dotenv_path=env_path)

client_id = os.getenv('SPOTIFY_CLIENT_ID')
client_secret = os.getenv('SPOTIFY_CLIENT_SECRET')
redirect_uri = os.getenv('SPOTIFY_REDIRECT_URI')
apigw_url = os.getenv('SPOTIFY_AUTH_API_GATEWAY_ENDPOINT')
apigw_key = os.getenv('SPOTIFY_AUTH_API_GATEWAY_KEY')
s3_bucket = os.getenv('S3_BUCKET_NAME')

sp_oauth = SpotifyOAuth(client_id=client_id,
    client_secret=client_secret,
    redirect_uri=redirect_uri,
    scope="user-library-read",
    cache_path='.cache')

print("Authenticating user...")

try:
    sp_oauth.get_access_token(as_dict=False) # remove "as_dict" when it is deprecated (DeprecationWarning is given when true as per 29/07/2024)
    token_info = sp_oauth.get_cached_token()
    access_token = token_info['access_token']
    refresh_token = token_info['refresh_token']
    print("Spotify authentication successful.")
except Exception as e:
    print(f"An error occurred while trying to authenticate user: {e}")

print("Sending access and refresh tokens to AWS API Gateway endpoint...")

response = requests.post(apigw_url,
    json = {
        "info": "Sending access and refresh tokens for Spotify authorisation",
        "bucket-name": s3_bucket,
        "access-token": access_token,
        "refresh-token": refresh_token,
        "client-id": client_id,
        "client-secret": client_secret,
        "redirect-uri": redirect_uri
    },
    headers = {
        "x-api-key": apigw_key,
        "Content-Type": "application/json"
    })

print("AWS Endpoint response:")
print(response.text)

os.remove(f"{main_dir}/.cache")



